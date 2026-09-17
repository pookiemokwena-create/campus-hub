package com.example.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.example.data.model.Announcement
import com.example.data.model.CampusEvent
import com.example.data.model.ChatMessage
import com.example.data.model.Course
import com.example.data.model.NotificationItem
import com.example.data.model.QaReply
import com.example.data.model.QaThread
import com.example.data.model.User

@Database(
    entities = [
        User::class,
        Course::class,
        Announcement::class,
        QaThread::class,
        QaReply::class,
        CampusEvent::class,
        NotificationItem::class,
        ChatMessage::class
    ],
    version = 4,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun campusDao(): CampusDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "campus_hub_database"
                ).fallbackToDestructiveMigration().build()
                INSTANCE = instance
                instance
            }
        }
    }
}
