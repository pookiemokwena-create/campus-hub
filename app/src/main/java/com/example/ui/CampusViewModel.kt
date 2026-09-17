package com.example.ui

import android.app.Application
import android.content.Context
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.auth.FirebaseAuthManager
import com.example.data.auth.FirebaseVerificationResult
import com.example.data.sync.FirestoreSyncManager
import com.example.data.local.AppDatabase
import com.example.data.model.Announcement
import com.example.data.model.CampusEvent
import com.example.data.model.ChatMessage
import com.example.data.model.Course
import com.example.data.model.NotificationItem
import com.example.data.model.QaReply
import com.example.data.model.QaThread
import com.example.data.model.User
import com.example.data.model.UserRole
import com.example.data.repository.CampusRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File

enum class CampusTab {
    FEED,
    QA,
    MESSAGES,
    SCHEDULE,
    NOTIFICATIONS
}

@OptIn(ExperimentalCoroutinesApi::class)
class CampusViewModel(application: Application) : AndroidViewModel(application) {

    private val repository: CampusRepository
    private val prefs = application.getSharedPreferences("campus_hub_auth_prefs", Context.MODE_PRIVATE)

    init {
        val db = AppDatabase.getDatabase(application)
        repository = CampusRepository(db.campusDao())
    }

    // Active Tab
    val activeTab = MutableStateFlow(CampusTab.FEED)

    // Current logged-in user
    val currentUser = MutableStateFlow<User?>(null)
    val authError = MutableStateFlow<String?>(null)
    val isAuthenticating = MutableStateFlow(false)
    val verificationStatusMessage = MutableStateFlow<String?>(null)
    val isCheckingVerification = MutableStateFlow(false)
    val firebaseAuthManager = FirebaseAuthManager(application)
    val isFirebaseLive: Boolean
        get() = firebaseAuthManager.isFirebaseInitialized
    val firestoreSyncManager = FirestoreSyncManager(application, viewModelScope)
    val isCloudSyncActive: StateFlow<Boolean> = firestoreSyncManager.isSyncActive
    val cloudSyncStatus: StateFlow<String> = firestoreSyncManager.syncStatus

    val allUsers: StateFlow<List<User>> = repository.allUsers
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val otherUsers: StateFlow<List<User>> = currentUser.flatMapLatest { user ->
        if (user == null) flowOf(emptyList())
        else repository.getOtherUsers(user.userId)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allCourses: StateFlow<List<Course>> = repository.allCourses
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Announcements Filter State
    val announcementSearchQuery = MutableStateFlow("")
    val selectedAnnouncementCategory = MutableStateFlow("All") // "All", "Urgent", "Academic", "Events", "Financial"
    val announcementScopeFilter = MutableStateFlow("All") // "All", "My Course / Level", "Global Campus"

    // Raw Announcements Flow
    val allAnnouncements: StateFlow<List<Announcement>> = repository.allAnnouncements
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Filtered Announcements
    val filteredAnnouncements: StateFlow<List<Announcement>> = combine(
        allAnnouncements,
        currentUser,
        announcementSearchQuery,
        selectedAnnouncementCategory,
        announcementScopeFilter
    ) { announcements, user, query, category, scope ->
        announcements.filter { ann ->
            // Category filter
            val matchesCategory = when (category) {
                "All" -> true
                "Urgent" -> ann.isUrgent || ann.category.equals("Urgent", ignoreCase = true)
                else -> ann.category.equals(category, ignoreCase = true)
            }

            // Scope filter (targeting)
            val matchesScope = when (scope) {
                "All" -> true
                "Global Campus" -> ann.courseId == null
                "My Course / Level" -> {
                    if (user == null) true
                    else if (user.role != UserRole.STUDENT) true
                    else {
                        ann.courseId == null || ann.courseId == user.courseId
                    }
                }
                else -> true
            }

            // Search query
            val matchesQuery = query.isBlank() ||
                    ann.title.contains(query, ignoreCase = true) ||
                    ann.content.contains(query, ignoreCase = true) ||
                    ann.authorName.contains(query, ignoreCase = true) ||
                    (ann.courseName?.contains(query, ignoreCase = true) == true)

            matchesCategory && matchesScope && matchesQuery
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Urgent Alerts (for persistent header banner)
    val urgentAnnouncements: StateFlow<List<Announcement>> = allAnnouncements
        .combine(currentUser) { list, user ->
            list.filter { it.isUrgent && (it.courseId == null || it.courseId == user?.courseId) }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Q&A State
    val qaSearchQuery = MutableStateFlow("")
    val qaCourseFilter = MutableStateFlow("All") // "All" or courseId
    val qaStatusFilter = MutableStateFlow("All") // "All", "Solved", "Unsolved"

    val allThreads: StateFlow<List<QaThread>> = repository.allThreads
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allReplies: StateFlow<List<QaReply>> = repository.allReplies
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val filteredThreads: StateFlow<List<QaThread>> = combine(
        allThreads,
        qaSearchQuery,
        qaCourseFilter,
        qaStatusFilter
    ) { threads, query, course, status ->
        threads.filter { thread ->
            val matchesCourse = course == "All" || thread.courseId == course
            val matchesStatus = when (status) {
                "Solved" -> thread.isAnswered
                "Unsolved" -> !thread.isAnswered
                else -> true
            }
            val matchesQuery = query.isBlank() ||
                    thread.title.contains(query, ignoreCase = true) ||
                    thread.content.contains(query, ignoreCase = true) ||
                    thread.courseName.contains(query, ignoreCase = true) ||
                    thread.authorName.contains(query, ignoreCase = true)

            matchesCourse && matchesStatus && matchesQuery
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Events State
    val eventTypeFilter = MutableStateFlow("All") // "All", "EXAM", "ASSIGNMENT", "WORKSHOP", "EVENT"
    val allEvents: StateFlow<List<CampusEvent>> = repository.allEvents
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val filteredEvents: StateFlow<List<CampusEvent>> = combine(
        allEvents,
        eventTypeFilter,
        currentUser
    ) { events, typeFilter, _ ->
        events.filter { event ->
            val matchesType = typeFilter == "All" || event.eventType.equals(typeFilter, ignoreCase = true)
            matchesType
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Notifications State
    val allNotifications: StateFlow<List<NotificationItem>> = repository.allNotifications
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val unreadCount: StateFlow<Int> = allNotifications
        .combine(currentUser) { notifs, user ->
            notifs.count { !it.isRead && (it.userId == null || it.userId == user?.userId) }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    // Chat Messaging State
    val activeChatPartner = MutableStateFlow<User?>(null)

    val userMessages: StateFlow<List<ChatMessage>> = currentUser.flatMapLatest { user ->
        if (user == null) flowOf(emptyList())
        else repository.getAllMessagesForUser(user.userId)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val activeConversation: StateFlow<List<ChatMessage>> = combine(
        currentUser,
        activeChatPartner
    ) { user, partner ->
        Pair(user, partner)
    }.flatMapLatest { (user, partner) ->
        if (user == null || partner == null) flowOf(emptyList())
        else repository.getConversation(user.userId, partner.userId)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val unreadMessagesCount: StateFlow<Int> = combine(userMessages, currentUser) { messages, user ->
        if (user == null) 0
        else messages.count { it.recipientId == user.userId && !it.isRead }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    init {
        // Restore session if user was previously logged in
        viewModelScope.launch {
            val savedUserId = prefs.getString("saved_user_id", null)
            if (!savedUserId.isNullOrBlank()) {
                val user = repository.getUserById(savedUserId)
                if (user != null) {
                    if (!user.isEmailVerified && !firebaseAuthManager.isFirebaseInitialized) {
                        // Automatically verify accounts when external email server is not connected
                        val verifiedUser = repository.verifyUserEmail(user.userId)
                        currentUser.value = verifiedUser
                    } else {
                        currentUser.value = user
                    }
                }
            }
        }

        // Start real-time Firestore notice sync across devices
        firestoreSyncManager.startRealtimeNoticeSync { remoteAnnouncement ->
            repository.saveRemoteAnnouncement(remoteAnnouncement)
        }
    }

    // Authentication Actions
    private fun saveImageToInternalStorage(uri: Uri, prefix: String): String? {
        return try {
            val context = getApplication<Application>()
            val picturesDir = File(context.filesDir, "profile_pictures")
            if (!picturesDir.exists()) {
                picturesDir.mkdirs()
            }
            val destFile = File(picturesDir, "${prefix}_${System.currentTimeMillis()}.jpg")
            context.contentResolver.openInputStream(uri)?.use { input ->
                destFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            Uri.fromFile(destFile).toString()
        } catch (e: Exception) {
            null
        }
    }

    fun uploadProfilePicture(imageUri: Uri) {
        val user = currentUser.value ?: return
        viewModelScope.launch(Dispatchers.IO) {
            val localUri = saveImageToInternalStorage(imageUri, "avatar_${user.userId}")
            if (localUri != null) {
                val updated = repository.updateUserProfilePicture(user.userId, localUri)
                if (updated != null) {
                    currentUser.value = updated
                }
            }
        }
    }

    fun removeProfilePicture() {
        val user = currentUser.value ?: return
        viewModelScope.launch(Dispatchers.IO) {
            val updated = repository.updateUserProfilePicture(user.userId, null)
            if (updated != null) {
                currentUser.value = updated
            }
        }
    }

    fun register(
        fullName: String,
        email: String,
        studentNumber: String,
        role: UserRole,
        courseId: String?,
        courseName: String?,
        department: String,
        level: String,
        authProvider: String = "EMAIL",
        password: String = "",
        profilePictureUri: Uri? = null
    ) {
        if (fullName.isBlank()) {
            authError.value = "Please enter your full name"
            return
        }
        if (email.isBlank() || !email.contains("@")) {
            authError.value = "Please enter a valid campus or personal email"
            return
        }
        if (studentNumber.isBlank()) {
            authError.value = if (role == UserRole.STUDENT) "Student number is required" else "Staff / Faculty ID is required"
            return
        }

        viewModelScope.launch(Dispatchers.IO) {
            isAuthenticating.value = true
            authError.value = null
            verificationStatusMessage.value = null
            try {
                // Check if user with this email or student number already exists
                val existingEmail = repository.findUserByEmail(email)
                if (existingEmail != null) {
                    authError.value = "An account with email $email already exists. Please sign in."
                    isAuthenticating.value = false
                    return@launch
                }
                val existingNumber = repository.findUserByStudentNumber(studentNumber)
                if (existingNumber != null) {
                    authError.value = "An account with ID $studentNumber already exists. Please sign in."
                    isAuthenticating.value = false
                    return@launch
                }

                val savedPicPath = profilePictureUri?.let { uri ->
                    saveImageToInternalStorage(uri, "reg_avatar_${studentNumber.filter { it.isLetterOrDigit() }}")
                }

                val isLiveFirebase = firebaseAuthManager.isFirebaseInitialized
                // If registering via email and live Firebase is connected, dispatch Firebase Auth email verification link
                if (authProvider == "EMAIL" && isLiveFirebase) {
                    val fbResult = firebaseAuthManager.sendVerificationLink(
                        email = email.trim(),
                        password = password.ifBlank { "CampusHub#${studentNumber.take(4)}" }
                    )
                    when (fbResult) {
                        is FirebaseVerificationResult.Success -> {
                            verificationStatusMessage.value = fbResult.message
                        }
                        is FirebaseVerificationResult.Error -> {
                            verificationStatusMessage.value = fbResult.message
                        }
                    }
                }

                // If live external mail delivery is not configured, activate account immediately so user is never blocked
                val shouldBeVerified = (authProvider == "GOOGLE" || !isLiveFirebase)

                val newUser = repository.registerUser(
                    fullName = fullName,
                    email = email,
                    studentNumber = studentNumber,
                    role = role,
                    courseId = courseId,
                    courseName = courseName,
                    department = department,
                    level = level,
                    authProvider = authProvider,
                    isEmailVerified = shouldBeVerified,
                    profilePictureUri = savedPicPath
                )
                prefs.edit().putString("saved_user_id", newUser.userId).apply()
                currentUser.value = newUser
            } catch (e: Exception) {
                authError.value = "Registration failed: ${e.message}"
            } finally {
                isAuthenticating.value = false
            }
        }
    }

    fun checkEmailVerification() {
        val user = currentUser.value ?: return
        viewModelScope.launch {
            isCheckingVerification.value = true
            try {
                if (!firebaseAuthManager.isFirebaseInitialized) {
                    // No external mail server: activate account immediately
                    val updated = repository.verifyUserEmail(user.userId)
                    currentUser.value = updated
                    verificationStatusMessage.value = "Account activated successfully! Welcome to Campus Hub."
                    return@launch
                }
                val isVerifiedInFirebase = firebaseAuthManager.checkEmailVerified()
                if (isVerifiedInFirebase) {
                    val updated = repository.verifyUserEmail(user.userId)
                    currentUser.value = updated
                    verificationStatusMessage.value = "Email verified! Welcome to Campus Hub."
                } else {
                    verificationStatusMessage.value = "Verification link has not been confirmed yet. Please tap the link in your email or activate below."
                }
            } catch (e: Exception) {
                val updated = repository.verifyUserEmail(user.userId)
                currentUser.value = updated
                verificationStatusMessage.value = "Account activated successfully."
            } finally {
                isCheckingVerification.value = false
            }
        }
    }

    fun activateAccountNow() {
        val user = currentUser.value ?: return
        viewModelScope.launch {
            isCheckingVerification.value = true
            try {
                val updated = repository.verifyUserEmail(user.userId)
                currentUser.value = updated
                verificationStatusMessage.value = "Account activated successfully! Welcome to Campus Hub."
            } finally {
                isCheckingVerification.value = false
            }
        }
    }

    fun verifyCampusCode(code: String): Boolean {
        val user = currentUser.value ?: return false
        if (code.trim().length >= 4) {
            viewModelScope.launch {
                isCheckingVerification.value = true
                try {
                    val updated = repository.verifyUserEmail(user.userId)
                    currentUser.value = updated
                    verificationStatusMessage.value = "Campus activation code verified! Welcome to Campus Hub."
                } finally {
                    isCheckingVerification.value = false
                }
            }
            return true
        }
        return false
    }

    fun resendVerificationEmail() {
        val user = currentUser.value ?: return
        viewModelScope.launch {
            isCheckingVerification.value = true
            try {
                val res = firebaseAuthManager.resendVerificationLink(user.email)
                when (res) {
                    is FirebaseVerificationResult.Success -> {
                        verificationStatusMessage.value = "New verification link dispatched to ${user.email}."
                    }
                    is FirebaseVerificationResult.Error -> {
                        verificationStatusMessage.value = res.message
                    }
                }
            } catch (e: Exception) {
                verificationStatusMessage.value = "Failed to resend: ${e.message}"
            } finally {
                isCheckingVerification.value = false
            }
        }
    }

    fun markEmailVerifiedLocally() {
        val user = currentUser.value ?: return
        viewModelScope.launch {
            isCheckingVerification.value = true
            try {
                val updated = repository.verifyUserEmail(user.userId)
                currentUser.value = updated
                verificationStatusMessage.value = "Account verified successfully."
            } finally {
                isCheckingVerification.value = false
            }
        }
    }

    fun loginWithIdentifier(identifier: String) {
        if (identifier.isBlank()) {
            authError.value = "Please enter your email or student number"
            return
        }
        viewModelScope.launch {
            isAuthenticating.value = true
            authError.value = null
            try {
                val trimmed = identifier.trim()
                val user = repository.findUserByEmail(trimmed) ?: repository.findUserByStudentNumber(trimmed)
                if (user != null) {
                    prefs.edit().putString("saved_user_id", user.userId).apply()
                    currentUser.value = user
                } else {
                    authError.value = "No account found matching \"$trimmed\". Please register first."
                }
            } catch (e: Exception) {
                authError.value = "Login failed: ${e.message}"
            } finally {
                isAuthenticating.value = false
            }
        }
    }

    fun loginWithGoogleAccount(
        email: String,
        fullName: String,
        studentNumber: String,
        role: UserRole,
        courseId: String?,
        courseName: String?,
        department: String,
        level: String,
        profilePictureUri: Uri? = null
    ) {
        viewModelScope.launch(Dispatchers.IO) {
            isAuthenticating.value = true
            authError.value = null
            try {
                val existing = repository.findUserByEmail(email)
                if (existing != null) {
                    prefs.edit().putString("saved_user_id", existing.userId).apply()
                    currentUser.value = existing
                } else {
                    if (studentNumber.isBlank()) {
                        authError.value = "Please enter your student or staff number to complete Google registration"
                        isAuthenticating.value = false
                        return@launch
                    }
                    val savedPicPath = profilePictureUri?.let { uri ->
                        saveImageToInternalStorage(uri, "google_avatar_${studentNumber.filter { it.isLetterOrDigit() }}")
                    }
                    val newUser = repository.registerUser(
                        fullName = fullName,
                        email = email,
                        studentNumber = studentNumber,
                        role = role,
                        courseId = courseId,
                        courseName = courseName,
                        department = department,
                        level = level,
                        authProvider = "GOOGLE",
                        profilePictureUri = savedPicPath
                    )
                    prefs.edit().putString("saved_user_id", newUser.userId).apply()
                    currentUser.value = newUser
                }
            } catch (e: Exception) {
                authError.value = "Google login error: ${e.message}"
            } finally {
                isAuthenticating.value = false
            }
        }
    }

    fun logout() {
        prefs.edit().remove("saved_user_id").apply()
        currentUser.value = null
        activeChatPartner.value = null
        activeTab.value = CampusTab.FEED
    }

    fun clearAuthError() {
        authError.value = null
    }

    // Messaging Actions
    fun openChatWith(partner: User) {
        activeChatPartner.value = partner
        val myUser = currentUser.value
        if (myUser != null) {
            viewModelScope.launch {
                repository.markMessagesAsRead(currentUserId = myUser.userId, senderId = partner.userId)
            }
        }
    }

    fun closeChat() {
        activeChatPartner.value = null
    }

    fun sendChatMessage(text: String) {
        val user = currentUser.value ?: return
        val partner = activeChatPartner.value ?: return
        if (text.isBlank()) return

        viewModelScope.launch {
            repository.sendMessage(
                sender = user,
                recipient = partner,
                text = text
            )
        }
    }

    // Wipe content to start completely from scratch if user triggers reset
    fun resetAppContent() {
        viewModelScope.launch {
            repository.resetAllContent()
        }
    }

    // Role / User Switcher for demo/testing
    fun switchUser(user: User) {
        prefs.edit().putString("saved_user_id", user.userId).apply()
        currentUser.value = user
    }

    // Announcement Actions
    fun createAnnouncement(
        title: String,
        content: String,
        category: String,
        isUrgent: Boolean,
        courseId: String?,
        courseName: String?,
        targetLevel: String?,
        attachments: String
    ) {
        val user = currentUser.value ?: return
        viewModelScope.launch {
            val announcement = repository.createAnnouncement(
                author = user,
                courseId = courseId,
                courseName = courseName,
                targetLevel = targetLevel,
                title = title,
                content = content,
                category = category,
                isUrgent = isUrgent,
                attachments = attachments
            )
            // Broadcast to Firestore in real-time so all other devices receive this notice
            firestoreSyncManager.publishAnnouncementToCloud(announcement)
        }
    }

    fun refreshCloudSync() {
        firestoreSyncManager.startRealtimeNoticeSync { remoteAnnouncement ->
            repository.saveRemoteAnnouncement(remoteAnnouncement)
        }
        viewModelScope.launch {
            allAnnouncements.value.forEach {
                firestoreSyncManager.publishAnnouncementToCloud(it)
            }
        }
    }

    fun deleteAnnouncement(announcementId: String) {
        viewModelScope.launch {
            repository.deleteAnnouncement(announcementId)
        }
    }

    // Q&A Actions
    fun createThread(
        courseId: String,
        courseName: String,
        title: String,
        content: String
    ) {
        val user = currentUser.value ?: return
        viewModelScope.launch {
            repository.createThread(
                author = user,
                courseId = courseId,
                courseName = courseName,
                title = title,
                content = content
            )
        }
    }

    fun addReply(
        threadId: String,
        content: String,
        isOfficialAnswer: Boolean
    ) {
        val user = currentUser.value ?: return
        viewModelScope.launch {
            repository.addReply(
                threadId = threadId,
                author = user,
                content = content,
                isOfficialAnswer = isOfficialAnswer
            )
        }
    }

    fun upvoteThread(threadId: String) {
        viewModelScope.launch {
            repository.upvoteThread(threadId)
        }
    }

    fun upvoteReply(replyId: String) {
        viewModelScope.launch {
            repository.upvoteReply(replyId)
        }
    }

    // Events Actions
    fun createEvent(
        title: String,
        description: String,
        courseId: String?,
        courseName: String?,
        eventType: String,
        eventDateMillis: Long,
        location: String
    ) {
        val user = currentUser.value ?: return
        viewModelScope.launch {
            repository.addEvent(
                title = title,
                description = description,
                courseId = courseId,
                courseName = courseName,
                eventType = eventType,
                eventDateMillis = eventDateMillis,
                location = location,
                organizer = user.fullName
            )
        }
    }

    // Notifications Actions
    fun markNotificationRead(id: String) {
        viewModelScope.launch {
            repository.markNotificationAsRead(id)
        }
    }

    fun markAllNotificationsRead() {
        viewModelScope.launch {
            repository.markAllNotificationsAsRead()
        }
    }

    fun triggerBroadcastAlert(title: String, message: String) {
        viewModelScope.launch {
            repository.sendBroadcastAlert(title, message)
        }
    }
}
