package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

enum class UserRole {
    STUDENT,
    LECTURER,
    ADMIN
}

@Entity(tableName = "users")
data class User(
    @PrimaryKey val userId: String,
    val fullName: String,
    val email: String,
    val studentNumber: String,
    val role: UserRole,
    val courseId: String?,
    val courseName: String?,
    val department: String,
    val level: String,
    val avatarColorHex: String,
    val authProvider: String = "EMAIL", // "GOOGLE" or "EMAIL"
    val isEmailVerified: Boolean = false,
    val profilePictureUri: String? = null
)

@Entity(tableName = "chat_messages")
data class ChatMessage(
    @PrimaryKey val messageId: String,
    val senderId: String,
    val senderName: String,
    val senderRole: UserRole,
    val recipientId: String,
    val recipientName: String,
    val recipientRole: UserRole,
    val text: String,
    val timestamp: Long = System.currentTimeMillis(),
    val isRead: Boolean = false
)

@Entity(tableName = "courses")
data class Course(
    @PrimaryKey val courseId: String,
    val courseName: String,
    val code: String,
    val department: String,
    val level: String
)

@Entity(tableName = "announcements")
data class Announcement(
    @PrimaryKey val announcementId: String,
    val authorId: String,
    val authorName: String,
    val authorRole: UserRole,
    val courseId: String?, // null if Campus-Wide / Global
    val courseName: String?,
    val targetLevel: String?, // e.g. "All Levels", "Level 3", "Level 1"
    val title: String,
    val content: String,
    val category: String, // "Urgent", "Academic", "Events", "Financial"
    val isUrgent: Boolean,
    val createdAt: Long = System.currentTimeMillis(),
    val attachments: String = "" // Comma-separated names of uploaded files/course materials
)

@Entity(tableName = "qa_threads")
data class QaThread(
    @PrimaryKey val threadId: String,
    val courseId: String,
    val courseName: String,
    val authorId: String,
    val authorName: String,
    val authorRole: UserRole,
    val title: String,
    val content: String,
    val isAnswered: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
    val upvotes: Int = 0
)

@Entity(tableName = "qa_replies")
data class QaReply(
    @PrimaryKey val replyId: String,
    val threadId: String,
    val authorId: String,
    val authorName: String,
    val authorRole: UserRole,
    val content: String,
    val isOfficialAnswer: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
    val upvotes: Int = 0
)

@Entity(tableName = "campus_events")
data class CampusEvent(
    @PrimaryKey val eventId: String,
    val title: String,
    val description: String,
    val courseId: String?, // null if general campus event
    val courseName: String?,
    val eventType: String, // "EXAM", "ASSIGNMENT", "WORKSHOP", "EVENT"
    val eventDateMillis: Long,
    val location: String,
    val organizer: String
)

@Entity(tableName = "notifications")
data class NotificationItem(
    @PrimaryKey val notificationId: String,
    val userId: String?, // null if broadcast to everyone
    val title: String,
    val message: String,
    val category: String, // "Urgent", "Academic", "Event", "Q&A"
    val isUrgent: Boolean,
    val isRead: Boolean = false,
    val createdAt: Long = System.currentTimeMillis()
)
