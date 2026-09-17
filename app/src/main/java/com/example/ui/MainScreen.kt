package com.example.ui

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.PickVisualMediaRequest
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.automirrored.outlined.Chat
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.QuestionAnswer
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.QuestionAnswer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.data.model.User
import com.example.data.model.UserRole
import com.example.ui.components.RoleBadge
import com.example.ui.components.UserAvatar
import com.example.ui.screens.AuthScreen
import com.example.ui.screens.EmailVerificationScreen
import com.example.ui.screens.FeedScreen
import com.example.ui.screens.MessagesScreen
import com.example.ui.screens.NotificationsScreen
import com.example.ui.screens.QaScreen
import com.example.ui.screens.ScheduleScreen
import com.example.ui.theme.CampusGold
import com.example.ui.theme.UrgentRed

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    viewModel: CampusViewModel,
    modifier: Modifier = Modifier
) {
    val currentUser by viewModel.currentUser.collectAsStateWithLifecycle()
    val activeTab by viewModel.activeTab.collectAsStateWithLifecycle()
    val allUsers by viewModel.allUsers.collectAsStateWithLifecycle()
    val unreadCount by viewModel.unreadCount.collectAsStateWithLifecycle()
    val unreadMessagesCount by viewModel.unreadMessagesCount.collectAsStateWithLifecycle()

    var showUserProfileDialog by remember { mutableStateOf(false) }

    // If no user is logged in / registered, show the Authentication & Registration Screen!
    if (currentUser == null) {
        AuthScreen(viewModel = viewModel, modifier = modifier)
        return
    }

    val user = currentUser!!

    // If user's email has not been verified via Firebase verification link, show EmailVerificationScreen!
    if (!user.isEmailVerified) {
        EmailVerificationScreen(
            viewModel = viewModel,
            user = user,
            modifier = modifier
        )
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 4.dp)
                    ) {
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(34.dp)
                        ) {
                            Box(
                                contentAlignment = Alignment.Center,
                                modifier = Modifier.fillMaxSize()
                            ) {
                                Icon(
                                    imageVector = Icons.Default.School,
                                    contentDescription = "Campus Hub",
                                    tint = CampusGold,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.width(10.dp))

                        Column {
                            Text(
                                text = "Campus Hub",
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 17.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                text = "Communication & Academic Portal",
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.outline
                            )
                        }
                    }
                },
                actions = {
                    // Active Profile Pill
                    Surface(
                        shape = RoundedCornerShape(20.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.65f),
                        modifier = Modifier
                            .clip(RoundedCornerShape(20.dp))
                            .clickable { showUserProfileDialog = true }
                            .border(
                                width = 1.dp,
                                color = MaterialTheme.colorScheme.outlineVariant,
                                shape = RoundedCornerShape(20.dp)
                            )
                            .testTag("active_user_profile_pill")
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            UserAvatar(user = user, size = 26)
                            Spacer(modifier = Modifier.width(6.dp))
                            Column {
                                Text(
                                    text = user.fullName.split(" ").firstOrNull() ?: user.fullName,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text(
                                    text = when (user.role) {
                                        UserRole.STUDENT -> "Student"
                                        UserRole.LECTURER -> "Lecturer"
                                        UserRole.ADMIN -> "Admin"
                                    },
                                    fontSize = 10.sp,
                                    color = when (user.role) {
                                        UserRole.STUDENT -> MaterialTheme.colorScheme.primary
                                        UserRole.LECTURER -> Color(0xFF166534)
                                        UserRole.ADMIN -> UrgentRed
                                    },
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            Icon(
                                imageVector = Icons.Default.ArrowDropDown,
                                contentDescription = "Profile Details",
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }

                    // Notification Bell with Badge
                    IconButton(
                        onClick = { viewModel.activeTab.value = CampusTab.NOTIFICATIONS },
                        modifier = Modifier.testTag("notifications_top_bar_button")
                    ) {
                        BadgedBox(
                            badge = {
                                if (unreadCount > 0) {
                                    Badge(
                                        containerColor = UrgentRed,
                                        contentColor = Color.White
                                    ) {
                                        Text("$unreadCount")
                                    }
                                }
                            }
                        ) {
                            Icon(
                                imageVector = if (activeTab == CampusTab.NOTIFICATIONS) Icons.Default.Notifications else Icons.Outlined.Notifications,
                                contentDescription = "Campus Notifications",
                                tint = if (activeTab == CampusTab.NOTIFICATIONS) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                ),
                modifier = Modifier.windowInsetsPadding(WindowInsets.statusBars)
            )
        },
        bottomBar = {
            NavigationBar(
                windowInsets = WindowInsets.navigationBars,
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 6.dp
            ) {
                // Tab 1: Notices
                NavigationBarItem(
                    selected = activeTab == CampusTab.FEED,
                    onClick = { viewModel.activeTab.value = CampusTab.FEED },
                    icon = {
                        Icon(
                            imageVector = if (activeTab == CampusTab.FEED) Icons.Default.Campaign else Icons.Outlined.Campaign,
                            contentDescription = "Notices"
                        )
                    },
                    label = { Text("Notices", fontSize = 11.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary
                    ),
                    modifier = Modifier.testTag("nav_tab_feed")
                )

                // Tab 2: Q&A
                NavigationBarItem(
                    selected = activeTab == CampusTab.QA,
                    onClick = { viewModel.activeTab.value = CampusTab.QA },
                    icon = {
                        Icon(
                            imageVector = if (activeTab == CampusTab.QA) Icons.Default.QuestionAnswer else Icons.Outlined.QuestionAnswer,
                            contentDescription = "Q&A"
                        )
                    },
                    label = { Text("Q&A", fontSize = 11.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary
                    ),
                    modifier = Modifier.testTag("nav_tab_qa")
                )

                // Tab 3: Messages
                NavigationBarItem(
                    selected = activeTab == CampusTab.MESSAGES,
                    onClick = { viewModel.activeTab.value = CampusTab.MESSAGES },
                    icon = {
                        BadgedBox(
                            badge = {
                                if (unreadMessagesCount > 0) {
                                    Badge(
                                        containerColor = MaterialTheme.colorScheme.primary,
                                        contentColor = MaterialTheme.colorScheme.onPrimary
                                    ) {
                                        Text("$unreadMessagesCount")
                                    }
                                }
                            }
                        ) {
                            Icon(
                                imageVector = if (activeTab == CampusTab.MESSAGES) Icons.AutoMirrored.Filled.Chat else Icons.AutoMirrored.Outlined.Chat,
                                contentDescription = "Messages"
                            )
                        }
                    },
                    label = { Text("Messages", fontSize = 11.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary
                    ),
                    modifier = Modifier.testTag("nav_tab_messages")
                )

                // Tab 4: Schedule
                NavigationBarItem(
                    selected = activeTab == CampusTab.SCHEDULE,
                    onClick = { viewModel.activeTab.value = CampusTab.SCHEDULE },
                    icon = {
                        Icon(
                            imageVector = if (activeTab == CampusTab.SCHEDULE) Icons.Default.CalendarMonth else Icons.Outlined.CalendarMonth,
                            contentDescription = "Schedule"
                        )
                    },
                    label = { Text("Schedule", fontSize = 11.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary
                    ),
                    modifier = Modifier.testTag("nav_tab_schedule")
                )

                // Tab 5: Alerts
                NavigationBarItem(
                    selected = activeTab == CampusTab.NOTIFICATIONS,
                    onClick = { viewModel.activeTab.value = CampusTab.NOTIFICATIONS },
                    icon = {
                        BadgedBox(
                            badge = {
                                if (unreadCount > 0) {
                                    Badge(
                                        containerColor = UrgentRed,
                                        contentColor = Color.White
                                    ) {
                                        Text("$unreadCount")
                                    }
                                }
                            }
                        ) {
                            Icon(
                                imageVector = if (activeTab == CampusTab.NOTIFICATIONS) Icons.Default.Notifications else Icons.Outlined.Notifications,
                                contentDescription = "Alerts"
                            )
                        }
                    },
                    label = { Text("Alerts", fontSize = 11.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary
                    ),
                    modifier = Modifier.testTag("nav_tab_notifications")
                )
            }
        },
        modifier = modifier.fillMaxSize()
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(MaterialTheme.colorScheme.background)
        ) {
            when (activeTab) {
                CampusTab.FEED -> FeedScreen(viewModel = viewModel)
                CampusTab.QA -> QaScreen(viewModel = viewModel)
                CampusTab.MESSAGES -> MessagesScreen(viewModel = viewModel)
                CampusTab.SCHEDULE -> ScheduleScreen(viewModel = viewModel)
                CampusTab.NOTIFICATIONS -> NotificationsScreen(viewModel = viewModel)
            }
        }
    }

    // User Profile Dialog
    if (showUserProfileDialog) {
        UserProfileDialog(
            user = user,
            otherUsers = allUsers.filter { it.userId != user.userId },
            onSwitchUser = {
                viewModel.switchUser(it)
                showUserProfileDialog = false
            },
            onUploadProfilePicture = { viewModel.uploadProfilePicture(it) },
            onRemoveProfilePicture = { viewModel.removeProfilePicture() },
            onLogout = {
                showUserProfileDialog = false
                viewModel.logout()
            },
            onResetContent = {
                showUserProfileDialog = false
                viewModel.resetAppContent()
            },
            onDismiss = { showUserProfileDialog = false }
        )
    }
}

@Composable
fun UserProfileDialog(
    user: User,
    otherUsers: List<User>,
    onSwitchUser: (User) -> Unit,
    onUploadProfilePicture: (Uri) -> Unit,
    onRemoveProfilePicture: () -> Unit,
    onLogout: () -> Unit,
    onResetContent: () -> Unit,
    onDismiss: () -> Unit
) {
    var confirmReset by remember { mutableStateOf(false) }

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        if (uri != null) {
            onUploadProfilePicture(uri)
        }
    }

    if (confirmReset) {
        AlertDialog(
            onDismissRequest = { confirmReset = false },
            title = { Text("Reset to Clean Slate?") },
            text = {
                Text("This will wipe all existing notices, Q&A discussions, events, messages, and notifications so the platform starts completely from scratch.")
            },
            confirmButton = {
                Button(
                    onClick = {
                        confirmReset = false
                        onResetContent()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) {
                    Text("Yes, Start from Scratch")
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmReset = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Box(contentAlignment = Alignment.BottomEnd) {
                    UserAvatar(user = user, size = 52)
                    Surface(
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.primary,
                        shadowElevation = 2.dp,
                        modifier = Modifier
                            .size(22.dp)
                            .clip(CircleShape)
                            .clickable {
                                photoPickerLauncher.launch(
                                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                )
                            }
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Default.CameraAlt,
                                contentDescription = "Change Profile Picture",
                                tint = Color.White,
                                modifier = Modifier.size(13.dp)
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(user.fullName, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    Spacer(modifier = Modifier.height(2.dp))
                    RoleBadge(role = user.role)
                }
            }
        },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                // Profile Picture Actions (Upload / Change / Remove)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = {
                            photoPickerLauncher.launch(
                                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                            )
                        },
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier
                            .weight(1f)
                            .testTag("upload_profile_picture_button")
                    ) {
                        Icon(
                            imageVector = Icons.Default.PhotoCamera,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = if (user.profilePictureUri.isNullOrBlank()) "Upload Photo" else "Change Photo",
                            fontSize = 12.sp
                        )
                    }

                    if (!user.profilePictureUri.isNullOrBlank()) {
                        OutlinedButton(
                            onClick = onRemoveProfilePicture,
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error),
                            modifier = Modifier.testTag("remove_profile_picture_button")
                        ) {
                            Icon(
                                imageVector = Icons.Default.Delete,
                                contentDescription = "Remove Photo",
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }

                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        ProfileInfoRow(
                            label = if (user.role == UserRole.STUDENT) "Student Number:" else "Staff ID:",
                            value = user.studentNumber
                        )
                        ProfileInfoRow(label = "Campus Email:", value = user.email)
                        ProfileInfoRow(label = "Department / Faculty:", value = user.department)
                        if (user.courseName != null) {
                            ProfileInfoRow(label = "Registered Course:", value = user.courseName)
                        }
                        ProfileInfoRow(label = "Academic Level:", value = user.level)
                        ProfileInfoRow(label = "Login Method:", value = if (user.authProvider == "GOOGLE") "Google Account" else "Email & Password")
                        ProfileInfoRow(label = "Verification:", value = if (user.isEmailVerified) "✓ Verified (Firebase)" else "Pending Verification")
                    }
                }

                if (otherUsers.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(14.dp))
                    Text(
                        text = "Switch Profile (Other Registered Users):",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    otherUsers.take(3).forEach { other ->
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = MaterialTheme.colorScheme.surface,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 2.dp)
                                .clickable { onSwitchUser(other) }
                                .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(8.dp))
                        ) {
                            Row(
                                modifier = Modifier.padding(8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                UserAvatar(user = other, size = 26)
                                Spacer(modifier = Modifier.width(8.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(other.fullName, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                    Text("ID: ${other.studentNumber} • ${other.role.name}", fontSize = 10.sp, color = MaterialTheme.colorScheme.outline)
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Start Clean Reset button
                OutlinedButton(
                    onClick = { confirmReset = true },
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.fillMaxWidth().testTag("reset_scratch_button")
                ) {
                    Icon(Icons.Default.DeleteSweep, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Clear All Content (Start from Scratch)", fontSize = 12.sp)
                }
            }
        },
        confirmButton = {
            Button(
                onClick = onLogout,
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                modifier = Modifier.testTag("logout_button")
            ) {
                Icon(Icons.Default.ExitToApp, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text("Log Out")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Close")
            }
        }
    )
}

@Composable
fun ProfileInfoRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 3.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, fontSize = 12.sp, color = MaterialTheme.colorScheme.outline)
        Text(value, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
    }
}
