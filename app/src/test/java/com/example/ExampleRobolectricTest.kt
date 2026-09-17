package com.example

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.example.data.local.AppDatabase
import com.example.data.model.Announcement
import com.example.data.model.ChatMessage
import com.example.data.model.Course
import com.example.data.model.User
import com.example.data.model.UserRole
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class ExampleRobolectricTest {

    private lateinit var database: AppDatabase

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, AppDatabase::class.java)
            .allowMainThreadQueries()
            .build()
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun readStringFromContext() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val appName = context.getString(R.string.app_name)
        assertEquals("Campus Hub", appName)
    }

    @Test
    fun verifyUserAndAnnouncementInsertAndQuery() = runBlocking {
        val dao = database.campusDao()

        val testUser = User(
            userId = "test_user_1",
            fullName = "Dean Marcus Vance",
            email = "admin@campus.edu",
            studentNumber = "ADM-001",
            role = UserRole.ADMIN,
            courseId = null,
            courseName = "Campus-Wide",
            department = "Administration",
            level = "Staff",
            avatarColorHex = "#DC2626",
            authProvider = "EMAIL"
        )
        dao.insertUser(testUser)

        val users = dao.getAllUsers().first()
        assertEquals(1, users.size)
        assertEquals("Dean Marcus Vance", users[0].fullName)

        val announcement = Announcement(
            announcementId = "ann_test_1",
            authorId = testUser.userId,
            authorName = testUser.fullName,
            authorRole = testUser.role,
            courseId = null,
            courseName = null,
            targetLevel = "All Levels",
            title = "Test Urgent Broadcast",
            content = "This is a test notification content.",
            category = "Urgent",
            isUrgent = true,
            attachments = "Sample.pdf"
        )
        dao.insertAnnouncement(announcement)

        val announcements = dao.getAllAnnouncements().first()
        assertEquals(1, announcements.size)
        assertTrue(announcements[0].isUrgent)
        assertEquals("Test Urgent Broadcast", announcements[0].title)
    }

    @Test
    fun verifyMessagingAndUserLookup() = runBlocking {
        val dao = database.campusDao()

        val student = User(
            userId = "stu_101",
            fullName = "Sarah Jenkins",
            email = "sarah.j@campus.edu",
            studentNumber = "STU-2026-9041",
            role = UserRole.STUDENT,
            courseId = "cs101",
            courseName = "BSc Computer Science",
            department = "School of Computing",
            level = "Year 2",
            avatarColorHex = "#2563EB",
            authProvider = "EMAIL"
        )
        val lecturer = User(
            userId = "lec_202",
            fullName = "Dr. Elena Rostova",
            email = "elena.r@campus.edu",
            studentNumber = "FAC-5012",
            role = UserRole.LECTURER,
            courseId = "cs101",
            courseName = "BSc Computer Science",
            department = "School of Computing",
            level = "Senior Faculty",
            avatarColorHex = "#166534",
            authProvider = "GOOGLE"
        )

        dao.insertUser(student)
        dao.insertUser(lecturer)

        // Lookup by student number
        val foundStudent = dao.findUserByStudentNumber("STU-2026-9041")
        assertEquals("Sarah Jenkins", foundStudent?.fullName)

        // Lookup by email
        val foundLecturer = dao.findUserByEmail("elena.r@campus.edu")
        assertEquals("Dr. Elena Rostova", foundLecturer?.fullName)

        // Send chat message
        val msg = ChatMessage(
            messageId = "msg_001",
            senderId = student.userId,
            senderName = student.fullName,
            senderRole = student.role,
            recipientId = lecturer.userId,
            recipientName = lecturer.fullName,
            recipientRole = lecturer.role,
            text = "Hello Dr. Rostova, will today's lecture be recorded?",
            timestamp = System.currentTimeMillis(),
            isRead = false
        )
        dao.insertMessage(msg)

        val conversation = dao.getConversation(student.userId, lecturer.userId).first()
        assertEquals(1, conversation.size)
        assertEquals("Hello Dr. Rostova, will today's lecture be recorded?", conversation[0].text)
        assertEquals(false, conversation[0].isRead)

        // Mark as read
        dao.markMessagesAsRead(currentUserId = lecturer.userId, senderId = student.userId)
        val updatedConvo = dao.getConversation(student.userId, lecturer.userId).first()
        assertEquals(true, updatedConvo[0].isRead)
    }

    @Test
    fun verifyEmailVerificationAndNcvCourse() = runBlocking {
        val dao = database.campusDao()

        val ncvStudent = User(
            userId = "ncv_stu_01",
            fullName = "Thabo Molefe",
            email = "thabo.m@tvet.edu",
            studentNumber = "NCV-2026-104",
            role = UserRole.STUDENT,
            courseId = "NCV_IT",
            courseName = "NC(V) Information Technology & Computer Science",
            department = "Information & Communication Technology",
            level = "NC(V) Level 3",
            avatarColorHex = "#059669",
            authProvider = "EMAIL",
            isEmailVerified = false
        )
        dao.insertUser(ncvStudent)

        val inserted = dao.getUserById("ncv_stu_01")
        assertEquals(false, inserted?.isEmailVerified)

        dao.markUserAsVerified("ncv_stu_01")
        val verified = dao.getUserById("ncv_stu_01")
        assertEquals(true, verified?.isEmailVerified)
    }

    @Test
    fun verifyRemoteNoticeSyncAndRetrieval() = runBlocking {
        val dao = database.campusDao()

        val remoteAnnouncement = Announcement(
            announcementId = "ann_cloud_999",
            authorId = "lecturer_cloud",
            authorName = "Prof. Dlamini",
            authorRole = UserRole.LECTURER,
            courseId = "NCV_IT",
            courseName = "NC(V) Information Technology & Computer Science",
            targetLevel = "NC(V) Level 3",
            title = "Final Practical Assessment Schedule Released",
            content = "Please check the schedule for your lab assessment on Friday.",
            category = "Academic",
            isUrgent = true,
            createdAt = System.currentTimeMillis()
        )

        dao.insertAnnouncement(remoteAnnouncement)

        val allNotices = dao.getAllAnnouncements().first()
        val found = allNotices.firstOrNull { it.announcementId == "ann_cloud_999" }
        assertNotNull(found)
        assertEquals("Final Practical Assessment Schedule Released", found?.title)
        assertEquals(true, found?.isUrgent)
    }
}
