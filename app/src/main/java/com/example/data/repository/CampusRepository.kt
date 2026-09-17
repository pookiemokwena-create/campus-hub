package com.example.data.repository

import com.example.data.local.CampusDao
import com.example.data.model.Announcement
import com.example.data.model.CampusEvent
import com.example.data.model.ChatMessage
import com.example.data.model.Course
import com.example.data.model.NotificationItem
import com.example.data.model.QaReply
import com.example.data.model.QaThread
import com.example.data.model.User
import com.example.data.model.UserRole
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch
import java.util.UUID

class CampusRepository(
    private val campusDao: CampusDao,
    private val scope: CoroutineScope = CoroutineScope(Dispatchers.IO)
) {

    val allUsers: Flow<List<User>> = campusDao.getAllUsers()
    val allCourses: Flow<List<Course>> = campusDao.getAllCourses()
    val allAnnouncements: Flow<List<Announcement>> = campusDao.getAllAnnouncements()
    val allThreads: Flow<List<QaThread>> = campusDao.getAllThreads()
    val allReplies: Flow<List<QaReply>> = campusDao.getAllReplies()
    val allEvents: Flow<List<CampusEvent>> = campusDao.getAllEvents()
    val allNotifications: Flow<List<NotificationItem>> = campusDao.getAllNotifications()

    init {
        scope.launch {
            seedCourseCatalogIfNeeded()
        }
    }

    // Only seeds the standard course and degree catalog so registering users can pick their course.
    // Only seeds the standard course and degree catalog so registering users can pick their course.
    // Announcements, Q&A threads, events, notifications, and messages start completely from scratch!
    private suspend fun seedCourseCatalogIfNeeded() {
        val existingCourses = campusDao.getAllCourses().firstOrNull().orEmpty()
        val existingIds = existingCourses.map { it.courseId }.toSet()

        val allCatalogCourses = listOf(
            // NC(V) Vocational Programmes
            Course(
                courseId = "NCV_IT",
                courseName = "NC(V) Information Technology & Computer Science",
                code = "NCV-IT",
                department = "Information & Communication Technology",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_CEBC",
                courseName = "NC(V) Civil Engineering & Building Construction",
                code = "NCV-CEBC",
                department = "Engineering & Built Environment",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_EIC",
                courseName = "NC(V) Electrical Infrastructure Construction",
                code = "NCV-EIC",
                department = "Engineering & Built Environment",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_ERD",
                courseName = "NC(V) Engineering & Related Design (Automotive / Fitting)",
                code = "NCV-ERD",
                department = "Engineering & Built Environment",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_MECH",
                courseName = "NC(V) Mechatronics & Automation",
                code = "NCV-MECH",
                department = "Engineering & Built Environment",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_FEA",
                courseName = "NC(V) Finance, Economics & Accounting",
                code = "NCV-FEA",
                department = "Business & Financial Studies",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_MGT",
                courseName = "NC(V) Management",
                code = "NCV-MGT",
                department = "Business Studies",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_MKT",
                courseName = "NC(V) Marketing",
                code = "NCV-MKT",
                department = "Business Studies",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_OA",
                courseName = "NC(V) Office Administration",
                code = "NCV-OA",
                department = "Business Studies",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_TL",
                courseName = "NC(V) Transport & Logistics",
                code = "NCV-TL",
                department = "Transport & Logistics",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_HOSP",
                courseName = "NC(V) Hospitality & Culinary Services",
                code = "NCV-HOSP",
                department = "Hospitality & Tourism",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_TOUR",
                courseName = "NC(V) Tourism",
                code = "NCV-TOUR",
                department = "Tourism & Hospitality",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_AGRI",
                courseName = "NC(V) Primary Agriculture",
                code = "NCV-AGRI",
                department = "Agricultural Sciences",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_SIS",
                courseName = "NC(V) Safety in Society",
                code = "NCV-SIS",
                department = "Governance, Law & Public Safety",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_ED",
                courseName = "NC(V) Education & Development",
                code = "NCV-ED",
                department = "Education & Social Development",
                level = "NC(V) Level 2 - 4"
            ),
            Course(
                courseId = "NCV_PPO",
                courseName = "NC(V) Process Plant Operations",
                code = "NCV-PPO",
                department = "Engineering & Built Environment",
                level = "NC(V) Level 2 - 4"
            ),
            // Degree & Diploma Programmes
            Course(
                courseId = "CS_301",
                courseName = "BSc Computer Science",
                code = "CS301",
                department = "Computer Science & IT",
                level = "Undergraduate"
            ),
            Course(
                courseId = "ENG_201",
                courseName = "Mechanical Engineering",
                code = "ME201",
                department = "Faculty of Engineering",
                level = "Undergraduate"
            ),
            Course(
                courseId = "EE_101",
                courseName = "Electrical & Electronic Engineering",
                code = "EE101",
                department = "Faculty of Engineering",
                level = "Undergraduate"
            ),
            Course(
                courseId = "BUS_102",
                courseName = "Business Finance & Economics",
                code = "BUS102",
                department = "School of Commerce",
                level = "Undergraduate"
            ),
            Course(
                courseId = "NHS_201",
                courseName = "Nursing & Health Sciences",
                code = "NHS201",
                department = "Health & Allied Sciences",
                level = "Diploma"
            ),
            Course(
                courseId = "LAW_101",
                courseName = "Bachelor of Laws (LLB)",
                code = "LAW101",
                department = "Faculty of Law",
                level = "Undergraduate"
            ),
            Course(
                courseId = "EDU_101",
                courseName = "Bachelor of Education",
                code = "EDU101",
                department = "Faculty of Education",
                level = "Undergraduate"
            )
        )

        val toInsert = allCatalogCourses.filter { it.courseId !in existingIds }
        if (toInsert.isNotEmpty()) {
            campusDao.insertCourses(toInsert)
        }
    }

    // User & Authentication Operations
    suspend fun registerUser(
        fullName: String,
        email: String,
        studentNumber: String,
        role: UserRole,
        courseId: String?,
        courseName: String?,
        department: String,
        level: String,
        authProvider: String = "EMAIL",
        isEmailVerified: Boolean = (authProvider == "GOOGLE"),
        profilePictureUri: String? = null
    ): User {
        val avatarPalette = listOf("#2563EB", "#7C3AED", "#059669", "#D97706", "#DC2626", "#0891B2", "#4F46E5", "#0D9488")
        val newUser = User(
            userId = "usr_${UUID.randomUUID().toString().take(8)}",
            fullName = fullName.trim(),
            email = email.trim().lowercase(),
            studentNumber = studentNumber.trim().uppercase(),
            role = role,
            courseId = courseId,
            courseName = courseName,
            department = department.ifBlank { "General Campus" },
            level = level.ifBlank { if (role == UserRole.STUDENT) "Year 1" else "Faculty" },
            avatarColorHex = avatarPalette.random(),
            authProvider = authProvider,
            isEmailVerified = isEmailVerified,
            profilePictureUri = profilePictureUri
        )
        campusDao.insertUser(newUser)

        // Welcome notification
        val welcomeNotif = NotificationItem(
            notificationId = "notif_${UUID.randomUUID()}",
            userId = newUser.userId,
            title = "Welcome to Campus Hub, ${newUser.fullName}!",
            message = "Your ${if (newUser.role == UserRole.STUDENT) "Student" else "Staff"} account ($studentNumber) has been created. Check notices and stay connected.",
            category = "Academic",
            isUrgent = false,
            isRead = false,
            createdAt = System.currentTimeMillis()
        )
        campusDao.insertNotification(welcomeNotif)

        return newUser
    }

    suspend fun verifyUserEmail(userId: String): User? {
        campusDao.markUserAsVerified(userId)
        val updated = campusDao.getUserById(userId)
        if (updated != null) {
            val verifiedNotif = NotificationItem(
                notificationId = "notif_${UUID.randomUUID()}",
                userId = updated.userId,
                title = "Email Verified Successfully",
                message = "Your campus email (${updated.email}) has been verified via Firebase Authentication. Full access granted.",
                category = "Academic",
                isUrgent = false,
                isRead = false,
                createdAt = System.currentTimeMillis()
            )
            campusDao.insertNotification(verifiedNotif)
        }
        return updated
    }

    suspend fun saveUser(user: User) {
        campusDao.insertUser(user)
    }

    suspend fun updateUserProfilePicture(userId: String, photoUri: String?): User? {
        campusDao.updateUserProfilePicture(userId, photoUri)
        return campusDao.getUserById(userId)
    }

    suspend fun getUserById(userId: String): User? =
        campusDao.getUserById(userId)

    suspend fun findUserByEmail(email: String): User? =
        campusDao.findUserByEmail(email.trim().lowercase())

    suspend fun findUserByStudentNumber(studentNumber: String): User? =
        campusDao.findUserByStudentNumber(studentNumber.trim().uppercase())

    fun getOtherUsers(currentUserId: String): Flow<List<User>> =
        campusDao.getOtherUsers(currentUserId)

    // Chat Messaging Operations
    fun getConversation(userId1: String, userId2: String): Flow<List<ChatMessage>> =
        campusDao.getConversation(userId1, userId2)

    fun getAllMessagesForUser(userId: String): Flow<List<ChatMessage>> =
        campusDao.getAllMessagesForUser(userId)

    suspend fun sendMessage(
        sender: User,
        recipient: User,
        text: String
    ): ChatMessage {
        val message = ChatMessage(
            messageId = "msg_${UUID.randomUUID()}",
            senderId = sender.userId,
            senderName = sender.fullName,
            senderRole = sender.role,
            recipientId = recipient.userId,
            recipientName = recipient.fullName,
            recipientRole = recipient.role,
            text = text.trim(),
            timestamp = System.currentTimeMillis(),
            isRead = false
        )
        campusDao.insertMessage(message)

        // Generate recipient notification
        val notif = NotificationItem(
            notificationId = "notif_${UUID.randomUUID()}",
            userId = recipient.userId,
            title = "New Message from ${sender.fullName}",
            message = if (text.length > 80) text.take(80) + "..." else text,
            category = "Message",
            isUrgent = false,
            isRead = false,
            createdAt = System.currentTimeMillis()
        )
        campusDao.insertNotification(notif)

        return message
    }

    suspend fun markMessagesAsRead(currentUserId: String, senderId: String) {
        campusDao.markMessagesAsRead(currentUserId, senderId)
    }

    // Reset content for starting from clean scratch
    suspend fun resetAllContent() {
        campusDao.clearAllAnnouncements()
        campusDao.clearAllThreads()
        campusDao.clearAllReplies()
        campusDao.clearAllEvents()
        campusDao.clearAllNotifications()
        campusDao.clearAllMessages()
    }

    fun getRepliesForThread(threadId: String): Flow<List<QaReply>> =
        campusDao.getRepliesForThread(threadId)

    suspend fun createAnnouncement(
        author: User,
        courseId: String?,
        courseName: String?,
        targetLevel: String?,
        title: String,
        content: String,
        category: String,
        isUrgent: Boolean,
        attachments: String
    ): Announcement {
        val announcement = Announcement(
            announcementId = "ann_${UUID.randomUUID().toString().take(12)}",
            authorId = author.userId,
            authorName = author.fullName,
            authorRole = author.role,
            courseId = courseId,
            courseName = courseName,
            targetLevel = targetLevel ?: "All Levels",
            title = title,
            content = content,
            category = category,
            isUrgent = isUrgent,
            createdAt = System.currentTimeMillis(),
            attachments = attachments
        )
        campusDao.insertAnnouncement(announcement)

        // Generate matching real-time notification
        val notif = NotificationItem(
            notificationId = "notif_${UUID.randomUUID()}",
            userId = null,
            title = if (isUrgent) "🚨 Urgent Notice: $title" else "New Notice: $title",
            message = if (content.length > 90) content.take(90) + "..." else content,
            category = category,
            isUrgent = isUrgent,
            isRead = false,
            createdAt = System.currentTimeMillis()
        )
        campusDao.insertNotification(notif)
        return announcement
    }

    suspend fun saveRemoteAnnouncement(announcement: Announcement) {
        campusDao.insertAnnouncement(announcement)
    }

    suspend fun deleteAnnouncement(announcementId: String) {
        campusDao.deleteAnnouncement(announcementId)
    }

    suspend fun createThread(
        author: User,
        courseId: String,
        courseName: String,
        title: String,
        content: String
    ) {
        val thread = QaThread(
            threadId = "thread_${UUID.randomUUID()}",
            courseId = courseId,
            courseName = courseName,
            authorId = author.userId,
            authorName = author.fullName,
            authorRole = author.role,
            title = title,
            content = content,
            isAnswered = false,
            createdAt = System.currentTimeMillis(),
            upvotes = 1
        )
        campusDao.insertThread(thread)
    }

    suspend fun addReply(
        threadId: String,
        author: User,
        content: String,
        isOfficialAnswer: Boolean
    ) {
        val reply = QaReply(
            replyId = "rep_${UUID.randomUUID()}",
            threadId = threadId,
            authorId = author.userId,
            authorName = author.fullName,
            authorRole = author.role,
            content = content,
            isOfficialAnswer = isOfficialAnswer,
            createdAt = System.currentTimeMillis(),
            upvotes = 1
        )
        campusDao.insertReply(reply)

        if (isOfficialAnswer) {
            campusDao.updateThreadAnswered(threadId, true)
            // Generate notification for students
            val notif = NotificationItem(
                notificationId = "notif_${UUID.randomUUID()}",
                userId = null,
                title = "Instructor Answered in Q&A",
                message = "${author.fullName} provided an official answer to a discussion thread.",
                category = "Q&A",
                isUrgent = false,
                isRead = false,
                createdAt = System.currentTimeMillis()
            )
            campusDao.insertNotification(notif)
        }
    }

    suspend fun upvoteThread(threadId: String) {
        campusDao.incrementThreadUpvote(threadId)
    }

    suspend fun upvoteReply(replyId: String) {
        campusDao.incrementReplyUpvote(replyId)
    }

    suspend fun addEvent(
        title: String,
        description: String,
        courseId: String?,
        courseName: String?,
        eventType: String,
        eventDateMillis: Long,
        location: String,
        organizer: String
    ) {
        val event = CampusEvent(
            eventId = "evt_${UUID.randomUUID()}",
            title = title,
            description = description,
            courseId = courseId,
            courseName = courseName,
            eventType = eventType,
            eventDateMillis = eventDateMillis,
            location = location,
            organizer = organizer
        )
        campusDao.insertEvent(event)

        // Notification for new calendar schedule item
        val notif = NotificationItem(
            notificationId = "notif_${UUID.randomUUID()}",
            userId = null,
            title = "New Schedule Item: $title",
            message = "Scheduled for $location (${eventType.lowercase().replaceFirstChar { it.uppercase() }}).",
            category = "Academic",
            isUrgent = eventType == "EXAM",
            isRead = false,
            createdAt = System.currentTimeMillis()
        )
        campusDao.insertNotification(notif)
    }

    suspend fun markNotificationAsRead(id: String) {
        campusDao.markNotificationAsRead(id)
    }

    suspend fun markAllNotificationsAsRead() {
        campusDao.markAllNotificationsAsRead()
    }

    suspend fun sendBroadcastAlert(title: String, message: String) {
        val notif = NotificationItem(
            notificationId = "notif_${UUID.randomUUID()}",
            userId = null,
            title = "🚨 $title",
            message = message,
            category = "Urgent",
            isUrgent = true,
            isRead = false,
            createdAt = System.currentTimeMillis()
        )
        campusDao.insertNotification(notif)
    }
}
