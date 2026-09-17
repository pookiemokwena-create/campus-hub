package com.example.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.example.data.model.Announcement
import com.example.data.model.CampusEvent
import com.example.data.model.ChatMessage
import com.example.data.model.Course
import com.example.data.model.NotificationItem
import com.example.data.model.QaReply
import com.example.data.model.QaThread
import com.example.data.model.User
import kotlinx.coroutines.flow.Flow

@Dao
interface CampusDao {

    // Users
    @Query("SELECT * FROM users ORDER BY fullName ASC")
    fun getAllUsers(): Flow<List<User>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsers(users: List<User>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: User)

    @Query("SELECT * FROM users WHERE userId = :userId LIMIT 1")
    suspend fun getUserById(userId: String): User?

    @Query("SELECT * FROM users WHERE email = :email LIMIT 1")
    suspend fun findUserByEmail(email: String): User?

    @Query("SELECT * FROM users WHERE studentNumber = :studentNumber LIMIT 1")
    suspend fun findUserByStudentNumber(studentNumber: String): User?

    @Query("SELECT * FROM users WHERE userId != :currentUserId ORDER BY fullName ASC")
    fun getOtherUsers(currentUserId: String): Flow<List<User>>

    @Query("UPDATE users SET isEmailVerified = 1 WHERE userId = :userId")
    suspend fun markUserAsVerified(userId: String)

    @Query("UPDATE users SET profilePictureUri = :photoUri WHERE userId = :userId")
    suspend fun updateUserProfilePicture(userId: String, photoUri: String?)

    // Chat Messages
    @Query("SELECT * FROM chat_messages WHERE (senderId = :userId1 AND recipientId = :userId2) OR (senderId = :userId2 AND recipientId = :userId1) ORDER BY timestamp ASC")
    fun getConversation(userId1: String, userId2: String): Flow<List<ChatMessage>>

    @Query("SELECT * FROM chat_messages WHERE senderId = :userId OR recipientId = :userId ORDER BY timestamp DESC")
    fun getAllMessagesForUser(userId: String): Flow<List<ChatMessage>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: ChatMessage)

    @Query("UPDATE chat_messages SET isRead = 1 WHERE recipientId = :currentUserId AND senderId = :senderId")
    suspend fun markMessagesAsRead(currentUserId: String, senderId: String)

    // Clear content helpers for starting clean
    @Query("DELETE FROM announcements")
    suspend fun clearAllAnnouncements()

    @Query("DELETE FROM qa_threads")
    suspend fun clearAllThreads()

    @Query("DELETE FROM qa_replies")
    suspend fun clearAllReplies()

    @Query("DELETE FROM campus_events")
    suspend fun clearAllEvents()

    @Query("DELETE FROM notifications")
    suspend fun clearAllNotifications()

    @Query("DELETE FROM chat_messages")
    suspend fun clearAllMessages()

    // Courses
    @Query("SELECT * FROM courses ORDER BY department, courseName")
    fun getAllCourses(): Flow<List<Course>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCourses(courses: List<Course>)

    // Announcements
    @Query("SELECT * FROM announcements ORDER BY isUrgent DESC, createdAt DESC")
    fun getAllAnnouncements(): Flow<List<Announcement>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAnnouncement(announcement: Announcement)

    @Query("DELETE FROM announcements WHERE announcementId = :announcementId")
    suspend fun deleteAnnouncement(announcementId: String)

    // Q&A Threads
    @Query("SELECT * FROM qa_threads ORDER BY createdAt DESC")
    fun getAllThreads(): Flow<List<QaThread>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertThread(thread: QaThread)

    @Query("UPDATE qa_threads SET isAnswered = :isAnswered WHERE threadId = :threadId")
    suspend fun updateThreadAnswered(threadId: String, isAnswered: Boolean)

    @Query("UPDATE qa_threads SET upvotes = upvotes + 1 WHERE threadId = :threadId")
    suspend fun incrementThreadUpvote(threadId: String)

    // Q&A Replies
    @Query("SELECT * FROM qa_replies WHERE threadId = :threadId ORDER BY isOfficialAnswer DESC, createdAt ASC")
    fun getRepliesForThread(threadId: String): Flow<List<QaReply>>

    @Query("SELECT * FROM qa_replies")
    fun getAllReplies(): Flow<List<QaReply>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReply(reply: QaReply)

    @Query("UPDATE qa_replies SET upvotes = upvotes + 1 WHERE replyId = :replyId")
    suspend fun incrementReplyUpvote(replyId: String)

    @Query("UPDATE qa_replies SET isOfficialAnswer = :isOfficial WHERE replyId = :replyId")
    suspend fun setReplyOfficial(replyId: String, isOfficial: Boolean)

    // Campus Events / Schedule
    @Query("SELECT * FROM campus_events ORDER BY eventDateMillis ASC")
    fun getAllEvents(): Flow<List<CampusEvent>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEvent(event: CampusEvent)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEvents(events: List<CampusEvent>)

    @Query("DELETE FROM campus_events WHERE eventId = :eventId")
    suspend fun deleteEvent(eventId: String)

    // Notifications
    @Query("SELECT * FROM notifications ORDER BY createdAt DESC")
    fun getAllNotifications(): Flow<List<NotificationItem>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNotification(notification: NotificationItem)

    @Query("UPDATE notifications SET isRead = 1 WHERE notificationId = :notificationId")
    suspend fun markNotificationAsRead(notificationId: String)

    @Query("UPDATE notifications SET isRead = 1")
    suspend fun markAllNotificationsAsRead()

    @Query("DELETE FROM notifications WHERE notificationId = :notificationId")
    suspend fun deleteNotification(notificationId: String)
}
