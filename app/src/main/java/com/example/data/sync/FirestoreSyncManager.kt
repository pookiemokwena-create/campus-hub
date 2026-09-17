package com.example.data.sync

import android.content.Context
import android.util.Log
import com.example.data.model.Announcement
import com.example.data.model.UserRole
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class FirestoreSyncManager(
    private val context: Context,
    private val coroutineScope: CoroutineScope
) {
    private val tag = "FirestoreSyncManager"

    private val _isSyncActive = MutableStateFlow(false)
    val isSyncActive: StateFlow<Boolean> = _isSyncActive.asStateFlow()

    private val _syncStatus = MutableStateFlow("Offline / Local Database")
    val syncStatus: StateFlow<String> = _syncStatus.asStateFlow()

    private val _lastSyncedCount = MutableStateFlow(0)
    val lastSyncedCount: StateFlow<Int> = _lastSyncedCount.asStateFlow()

    private var announcementListenerRegistration: ListenerRegistration? = null

    private val isFirebaseConfigured: Boolean
        get() = try {
            FirebaseApp.getApps(context).isNotEmpty()
        } catch (e: Exception) {
            Log.w(tag, "Firebase not initialized: ${e.message}")
            false
        }

    private val firestore: FirebaseFirestore?
        get() = if (isFirebaseConfigured) {
            try {
                FirebaseFirestore.getInstance()
            } catch (e: Exception) {
                Log.w(tag, "Firestore not available: ${e.message}")
                null
            }
        } else null

    /**
     * Starts listening to cloud announcements in real time from the "announcements" collection.
     * When any notice is added or modified by any user on any device, it triggers [onAnnouncementReceived].
     */
    fun startRealtimeNoticeSync(onAnnouncementReceived: suspend (Announcement) -> Unit) {
        val db = firestore
        if (db == null) {
            _isSyncActive.value = false
            _syncStatus.value = "Local Mode (Connect google-services.json for live cloud)"
            Log.d(tag, "Firestore not connected. Running local database fallback.")
            return
        }

        try {
            announcementListenerRegistration?.remove()
            _syncStatus.value = "Connecting to Firestore notices..."

            announcementListenerRegistration = db.collection("announcements")
                .addSnapshotListener { snapshots, error ->
                    if (error != null) {
                        Log.w(tag, "Firestore listen failed: ${error.message}")
                        _isSyncActive.value = false
                        _syncStatus.value = "Sync error: ${error.localizedMessage ?: "Connection failed"}"
                        return@addSnapshotListener
                    }

                    if (snapshots != null) {
                        _isSyncActive.value = true
                        _syncStatus.value = "Live Firestore Cloud Sync Active"
                        _lastSyncedCount.value = snapshots.size()

                        coroutineScope.launch(Dispatchers.IO) {
                            for (docChange in snapshots.documentChanges) {
                                try {
                                    val data = docChange.document.data
                                    val announcement = docToAnnouncement(docChange.document.id, data)
                                    if (announcement != null) {
                                        onAnnouncementReceived(announcement)
                                    }
                                } catch (e: Exception) {
                                    Log.e(tag, "Error parsing Firestore announcement doc: ${e.message}")
                                }
                            }
                        }
                    }
                }
        } catch (e: Exception) {
            Log.e(tag, "Failed to start Firestore listener", e)
            _isSyncActive.value = false
            _syncStatus.value = "Firestore offline"
        }
    }

    /**
     * Publishes an announcement to Firestore collection so all devices receive it instantly.
     */
    suspend fun publishAnnouncementToCloud(announcement: Announcement): Boolean {
        val db = firestore ?: return false
        return try {
            val map = hashMapOf(
                "announcementId" to announcement.announcementId,
                "authorId" to announcement.authorId,
                "authorName" to announcement.authorName,
                "authorRole" to announcement.authorRole.name,
                "courseId" to (announcement.courseId ?: ""),
                "courseName" to (announcement.courseName ?: ""),
                "targetLevel" to (announcement.targetLevel ?: "All Levels"),
                "title" to announcement.title,
                "content" to announcement.content,
                "category" to announcement.category,
                "isUrgent" to announcement.isUrgent,
                "createdAt" to announcement.createdAt,
                "attachments" to announcement.attachments
            )
            db.collection("announcements")
                .document(announcement.announcementId)
                .set(map, SetOptions.merge())
                .await()
            Log.d(tag, "Published notice ${announcement.announcementId} to Firestore successfully")
            true
        } catch (e: Exception) {
            Log.e(tag, "Failed to write notice to Firestore: ${e.message}")
            false
        }
    }

    private fun docToAnnouncement(docId: String, map: Map<String, Any>): Announcement? {
        val title = map["title"] as? String ?: return null
        val content = map["content"] as? String ?: ""
        val authorId = map["authorId"] as? String ?: "unknown"
        val authorName = map["authorName"] as? String ?: "Campus User"
        val authorRoleStr = map["authorRole"] as? String ?: "STUDENT"
        val authorRole = try {
            UserRole.valueOf(authorRoleStr)
        } catch (e: Exception) {
            UserRole.STUDENT
        }
        val courseId = (map["courseId"] as? String)?.takeIf { it.isNotBlank() }
        val courseName = (map["courseName"] as? String)?.takeIf { it.isNotBlank() }
        val targetLevel = (map["targetLevel"] as? String) ?: "All Levels"
        val category = (map["category"] as? String) ?: "Academic"
        val isUrgent = map["isUrgent"] as? Boolean ?: false
        val createdAt = (map["createdAt"] as? Number)?.toLong() ?: System.currentTimeMillis()
        val attachments = map["attachments"] as? String ?: ""

        return Announcement(
            announcementId = docId,
            authorId = authorId,
            authorName = authorName,
            authorRole = authorRole,
            courseId = courseId,
            courseName = courseName,
            targetLevel = targetLevel,
            title = title,
            content = content,
            category = category,
            isUrgent = isUrgent,
            createdAt = createdAt,
            attachments = attachments
        )
    }

    fun stopSync() {
        announcementListenerRegistration?.remove()
        announcementListenerRegistration = null
        _isSyncActive.value = false
    }
}
