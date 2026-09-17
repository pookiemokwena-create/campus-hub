package com.example.ui.screens

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
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SecondaryTabRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.data.model.Course
import com.example.data.model.UserRole
import com.example.ui.CampusViewModel

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun AuthScreen(
    viewModel: CampusViewModel,
    modifier: Modifier = Modifier
) {
    val authError by viewModel.authError.collectAsState()
    val isAuthenticating by viewModel.isAuthenticating.collectAsState()
    val allCourses by viewModel.allCourses.collectAsState()

    var selectedTab by remember { mutableIntStateOf(0) } // 0 = Register, 1 = Sign In
    var showGoogleDialog by remember { mutableStateOf(false) }

    // Registration Form State
    var regFullName by remember { mutableStateOf("") }
    var regEmail by remember { mutableStateOf("") }
    var regStudentNumber by remember { mutableStateOf("") }
    var regPassword by remember { mutableStateOf("") }
    var regPasswordVisible by remember { mutableStateOf(false) }
    var regRole by remember { mutableStateOf(UserRole.STUDENT) }
    var regSelectedCourse by remember { mutableStateOf<Course?>(null) }
    var regCourseExpanded by remember { mutableStateOf(false) }
    var regLevel by remember { mutableStateOf("Year 1") }
    var regProfilePictureUri by remember { mutableStateOf<Uri?>(null) }

    // Sign In Form State
    var loginIdentifier by remember { mutableStateOf("") }
    var loginPassword by remember { mutableStateOf("") }
    var loginPasswordVisible by remember { mutableStateOf(false) }

    // Google Sign In Completion Dialog State
    var googleAccountEmail by remember { mutableStateOf("pookiemokwena@gmail.com") }
    var googleAccountName by remember { mutableStateOf("Pookie Mokwena") }
    var showGoogleCompletionDialog by remember { mutableStateOf(false) }
    var googleStudentNumber by remember { mutableStateOf("") }
    var googleRole by remember { mutableStateOf(UserRole.STUDENT) }
    var googleSelectedCourse by remember { mutableStateOf<Course?>(null) }
    var googleCourseExpanded by remember { mutableStateOf(false) }
    var googleLevel by remember { mutableStateOf("Year 1") }
    var googleProfilePictureUri by remember { mutableStateOf<Uri?>(null) }

    val regPhotoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        if (uri != null) {
            regProfilePictureUri = uri
        }
    }

    val googlePhotoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        if (uri != null) {
            googleProfilePictureUri = uri
        }
    }

    Surface(
        modifier = modifier
            .fillMaxSize()
            .imePadding(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(16.dp))

            // Campus Brand Header
            Box(
                modifier = Modifier
                    .size(68.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.School,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(38.dp)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "Campus Hub",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground
            )

            Text(
                text = "Centralized Student, Lecturer & Staff Network",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(20.dp))

            // Google One-Tap Login Button
            OutlinedButton(
                onClick = { showGoogleDialog = true },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .testTag("google_login_button"),
                shape = RoundedCornerShape(12.dp),
                border = ButtonDefaults.outlinedButtonBorder.copy(width = 1.2.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    // Google stylized G badge
                    Box(
                        modifier = Modifier
                            .size(24.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF4285F4)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("G", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Continue with Google",
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(1.dp)
                        .background(MaterialTheme.colorScheme.outlineVariant)
                )
                Text(
                    text = "  or with email & student ID  ",
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.outline
                )
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(1.dp)
                        .background(MaterialTheme.colorScheme.outlineVariant)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Tab Selector: Register vs Sign In
            SecondaryTabRow(
                selectedTabIndex = selectedTab,
                modifier = Modifier.fillMaxWidth()
            ) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = {
                        selectedTab = 0
                        viewModel.clearAuthError()
                    },
                    text = { Text("Register", fontWeight = FontWeight.Bold) },
                    modifier = Modifier.testTag("tab_register")
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = {
                        selectedTab = 1
                        viewModel.clearAuthError()
                    },
                    text = { Text("Sign In", fontWeight = FontWeight.Bold) },
                    modifier = Modifier.testTag("tab_signin")
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Auth Error Banner
            if (authError != null) {
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp)
                        .testTag("auth_error_card")
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = authError ?: "",
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            fontSize = 13.sp
                        )
                    }
                }
            }

            if (selectedTab == 0) {
                // ================= REGISTRATION FORM =================
                Column(modifier = Modifier.fillMaxWidth()) {
                    // Role Selector
                    Text(
                        text = "I am registering as:",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(6.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf(
                            UserRole.STUDENT to "Student",
                            UserRole.LECTURER to "Lecturer",
                            UserRole.ADMIN to "Admin"
                        ).forEach { (role, label) ->
                            FilterChip(
                                selected = regRole == role,
                                onClick = { regRole = role },
                                label = { Text(label, fontSize = 12.sp) },
                                leadingIcon = if (regRole == role) {
                                    { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(14.dp)) }
                                } else null,
                                modifier = Modifier
                                    .weight(1f)
                                    .testTag("role_chip_${role.name}")
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Profile Photo Upload (Optional)
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Box(
                                contentAlignment = Alignment.BottomEnd,
                                modifier = Modifier.size(76.dp)
                            ) {
                                if (regProfilePictureUri != null) {
                                    AsyncImage(
                                        model = regProfilePictureUri,
                                        contentDescription = "Selected Profile Picture",
                                        contentScale = ContentScale.Crop,
                                        modifier = Modifier
                                            .size(76.dp)
                                            .clip(CircleShape)
                                            .border(2.dp, MaterialTheme.colorScheme.primary, CircleShape)
                                    )
                                } else {
                                    Surface(
                                        shape = CircleShape,
                                        color = MaterialTheme.colorScheme.primaryContainer,
                                        modifier = Modifier
                                            .size(76.dp)
                                            .clickable {
                                                regPhotoPickerLauncher.launch(
                                                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                                )
                                            }
                                            .testTag("reg_photo_picker_avatar")
                                    ) {
                                        Box(contentAlignment = Alignment.Center) {
                                            Icon(
                                                imageVector = Icons.Default.AddAPhoto,
                                                contentDescription = "Upload Profile Photo",
                                                tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                                modifier = Modifier.size(30.dp)
                                            )
                                        }
                                    }
                                }

                                Surface(
                                    shape = CircleShape,
                                    color = MaterialTheme.colorScheme.primary,
                                    shadowElevation = 3.dp,
                                    modifier = Modifier
                                        .size(26.dp)
                                        .clip(CircleShape)
                                        .clickable {
                                            regPhotoPickerLauncher.launch(
                                                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                            )
                                        }
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(
                                            imageVector = Icons.Default.CameraAlt,
                                            contentDescription = "Choose Photo",
                                            tint = Color.White,
                                            modifier = Modifier.size(14.dp)
                                        )
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(4.dp))

                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = if (regProfilePictureUri != null) "Photo Added" else "Add Profile Photo (Optional)",
                                    fontSize = 11.sp,
                                    color = if (regProfilePictureUri != null) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline,
                                    fontWeight = FontWeight.Medium
                                )
                                if (regProfilePictureUri != null) {
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = "Remove",
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.error,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier.clickable { regProfilePictureUri = null }
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Full Name
                    OutlinedTextField(
                        value = regFullName,
                        onValueChange = { regFullName = it },
                        label = { Text("Full Name") },
                        placeholder = { Text("e.g. Alex Chen") },
                        leadingIcon = { Icon(Icons.Default.Person, contentDescription = null) },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(
                            capitalization = KeyboardCapitalization.Words,
                            imeAction = ImeAction.Next
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("reg_fullname_input")
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    // Email
                    OutlinedTextField(
                        value = regEmail,
                        onValueChange = { regEmail = it },
                        label = { Text("Email Address") },
                        placeholder = { Text("e.g. student@campus.edu") },
                        leadingIcon = { Icon(Icons.Default.Email, contentDescription = null) },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Email,
                            imeAction = ImeAction.Next
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("reg_email_input")
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    // Student Number (or Staff ID)
                    val idLabel = if (regRole == UserRole.STUDENT) "Student Number *" else "Staff / Faculty ID *"
                    val idHint = if (regRole == UserRole.STUDENT) "e.g. STU-2026-9041 or 2026849" else "e.g. FAC-4081"

                    OutlinedTextField(
                        value = regStudentNumber,
                        onValueChange = { regStudentNumber = it.uppercase() },
                        label = { Text(idLabel) },
                        placeholder = { Text(idHint) },
                        leadingIcon = { Icon(Icons.Default.Badge, contentDescription = null) },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(
                            capitalization = KeyboardCapitalization.Characters,
                            imeAction = ImeAction.Next
                        ),
                        supportingText = { Text("Required for verification & campus records") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("reg_student_number_input")
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    // Password
                    OutlinedTextField(
                        value = regPassword,
                        onValueChange = { regPassword = it },
                        label = { Text("Create Password") },
                        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                        trailingIcon = {
                            IconButton(onClick = { regPasswordVisible = !regPasswordVisible }) {
                                Icon(
                                    imageVector = if (regPasswordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                                    contentDescription = "Toggle password visibility"
                                )
                            }
                        },
                        visualTransformation = if (regPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Password,
                            imeAction = ImeAction.Done
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("reg_password_input")
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    // Degree / Course Selector
                    ExposedDropdownMenuBox(
                        expanded = regCourseExpanded,
                        onExpandedChange = { regCourseExpanded = !regCourseExpanded },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        OutlinedTextField(
                            value = regSelectedCourse?.courseName ?: "General / Other Faculty",
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Course / Department") },
                            leadingIcon = { Icon(Icons.Default.School, contentDescription = null) },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = regCourseExpanded) },
                            modifier = Modifier
                                .menuAnchor()
                                .fillMaxWidth()
                                .testTag("reg_course_dropdown")
                        )
                        ExposedDropdownMenu(
                            expanded = regCourseExpanded,
                            onDismissRequest = { regCourseExpanded = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("General Campus / Other Faculty") },
                                onClick = {
                                    regSelectedCourse = null
                                    regCourseExpanded = false
                                }
                            )

                            // NC(V) Programmes Section Header
                            DropdownMenuItem(
                                text = {
                                    Text(
                                        "── NC(V) VOCATIONAL PROGRAMMES ──",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                },
                                onClick = {},
                                enabled = false
                            )
                            allCourses.filter { it.courseName.startsWith("NC(V)") }.forEach { course ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(course.courseName, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                            Text("${course.code} • ${course.department}", fontSize = 11.sp, color = MaterialTheme.colorScheme.outline)
                                        }
                                    },
                                    onClick = {
                                        regSelectedCourse = course
                                        regCourseExpanded = false
                                        if (!regLevel.startsWith("NC(V)")) {
                                            regLevel = "NC(V) Level 2"
                                        }
                                    }
                                )
                            }

                            // University Degrees Section Header
                            DropdownMenuItem(
                                text = {
                                    Text(
                                        "── DEGREES & DIPLOMAS ──",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                },
                                onClick = {},
                                enabled = false
                            )
                            allCourses.filter { !it.courseName.startsWith("NC(V)") }.forEach { course ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(course.courseName, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                            Text("${course.code} • ${course.department}", fontSize = 11.sp, color = MaterialTheme.colorScheme.outline)
                                        }
                                    },
                                    onClick = {
                                        regSelectedCourse = course
                                        regCourseExpanded = false
                                        if (regLevel.startsWith("NC(V)")) {
                                            regLevel = "Year 1"
                                        }
                                    }
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Academic Level
                    Text(
                        text = "Academic Level / Year:",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(4.dp))

                    val isNcvSelected = regSelectedCourse?.courseName?.startsWith("NC(V)") == true
                    val levels = if (regRole == UserRole.STUDENT) {
                        if (isNcvSelected) {
                            listOf("NC(V) Level 2", "NC(V) Level 3", "NC(V) Level 4", "Year 1", "Year 2")
                        } else {
                            listOf("Year 1", "Year 2", "Year 3", "Year 4 / Honours", "NC(V) Level 2", "NC(V) Level 3", "NC(V) Level 4", "Postgraduate")
                        }
                    } else {
                        listOf("Lecturer / Instructor", "Senior Lecturer", "Department Head", "Campus Admin")
                    }

                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        levels.forEach { level ->
                            FilterChip(
                                selected = regLevel == level,
                                onClick = { regLevel = level },
                                label = { Text(level, fontSize = 11.sp) }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    Button(
                        onClick = {
                            viewModel.register(
                                fullName = regFullName,
                                email = regEmail,
                                studentNumber = regStudentNumber,
                                role = regRole,
                                courseId = regSelectedCourse?.courseId,
                                courseName = regSelectedCourse?.courseName,
                                department = regSelectedCourse?.department ?: "General Campus",
                                level = regLevel,
                                authProvider = "EMAIL",
                                password = regPassword,
                                profilePictureUri = regProfilePictureUri
                            )
                        },
                        enabled = !isAuthenticating,
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp)
                            .testTag("submit_registration_button")
                    ) {
                        if (isAuthenticating) {
                            CircularProgressIndicator(color = Color.White, modifier = Modifier.size(22.dp))
                        } else {
                            Text("Register & Send Verification Link", fontSize = 14.sp, fontWeight = FontWeight.Bold)
                        }
                    }

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = "A Firebase verification link will be sent to your email to verify your identity.",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.outline,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            } else {
                // ================= SIGN IN FORM =================
                Column(modifier = Modifier.fillMaxWidth()) {
                    OutlinedTextField(
                        value = loginIdentifier,
                        onValueChange = { loginIdentifier = it },
                        label = { Text("Email or Student Number") },
                        placeholder = { Text("e.g. alex@campus.edu or 2026849") },
                        leadingIcon = { Icon(Icons.Default.AccountCircle, contentDescription = null) },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(
                            imeAction = ImeAction.Next
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("login_identifier_input")
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = loginPassword,
                        onValueChange = { loginPassword = it },
                        label = { Text("Password") },
                        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                        trailingIcon = {
                            IconButton(onClick = { loginPasswordVisible = !loginPasswordVisible }) {
                                Icon(
                                    imageVector = if (loginPasswordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                                    contentDescription = "Toggle password visibility"
                                )
                            }
                        },
                        visualTransformation = if (loginPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Password,
                            imeAction = ImeAction.Done
                        ),
                        keyboardActions = KeyboardActions(
                            onDone = {
                                viewModel.loginWithIdentifier(loginIdentifier)
                            }
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("login_password_input")
                    )

                    Spacer(modifier = Modifier.height(20.dp))

                    Button(
                        onClick = {
                            viewModel.loginWithIdentifier(loginIdentifier)
                        },
                        enabled = !isAuthenticating,
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp)
                            .testTag("submit_login_button")
                    ) {
                        if (isAuthenticating) {
                            CircularProgressIndicator(color = Color.White, modifier = Modifier.size(22.dp))
                        } else {
                            Text("Sign In to Campus Hub", fontSize = 15.sp, fontWeight = FontWeight.Bold)
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    TextButton(
                        onClick = { selectedTab = 0 },
                        modifier = Modifier.align(Alignment.CenterHorizontally)
                    ) {
                        Text("Don't have an account yet? Register here")
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }

    // Google Account Picker Dialog
    if (showGoogleDialog) {
        AlertDialog(
            onDismissRequest = { showGoogleDialog = false },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(24.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF4285F4)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("G", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    }
                    Spacer(modifier = Modifier.width(10.dp))
                    Text("Sign in with Google", fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column {
                    Text(
                        text = "Select a Google Account to continue with Campus Hub:",
                        fontSize = 13.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(14.dp))

                    // Default user Google account
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                showGoogleDialog = false
                                googleAccountEmail = "pookiemokwena@gmail.com"
                                googleAccountName = "Pookie Mokwena"
                                showGoogleCompletionDialog = true
                            }
                            .testTag("google_account_default")
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFFEA4335)),
                                contentAlignment = Alignment.Center
                            ) {
                                Text("P", color = Color.White, fontWeight = FontWeight.Bold)
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Column {
                                Text("Pookie Mokwena", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                                Text("pookiemokwena@gmail.com", fontSize = 12.sp, color = MaterialTheme.colorScheme.outline)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Custom Google account option
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = MaterialTheme.colorScheme.surface,
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(12.dp))
                            .clickable {
                                showGoogleDialog = false
                                googleAccountEmail = "campus.student@gmail.com"
                                googleAccountName = "Campus Student"
                                showGoogleCompletionDialog = true
                            }
                            .testTag("google_account_custom")
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.AccountCircle,
                                contentDescription = null,
                                modifier = Modifier.size(36.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Column {
                                Text("Use another Google account", fontWeight = FontWeight.Medium, fontSize = 14.sp)
                                Text("Sign in with your personal or student Google account", fontSize = 11.sp, color = MaterialTheme.colorScheme.outline)
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showGoogleDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Google Registration Details Dialog (if registering with Google, we must collect student number)
    if (showGoogleCompletionDialog) {
        AlertDialog(
            onDismissRequest = { showGoogleCompletionDialog = false },
            title = {
                Text("Complete Registration Details", fontWeight = FontWeight.Bold)
            },
            text = {
                Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                    Text(
                        text = "Connected with: $googleAccountEmail",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(10.dp))

                    // Optional Photo for Google Profile
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Box(
                                contentAlignment = Alignment.BottomEnd,
                                modifier = Modifier.size(68.dp)
                            ) {
                                if (googleProfilePictureUri != null) {
                                    AsyncImage(
                                        model = googleProfilePictureUri,
                                        contentDescription = "Selected Profile Picture",
                                        contentScale = ContentScale.Crop,
                                        modifier = Modifier
                                            .size(68.dp)
                                            .clip(CircleShape)
                                            .border(2.dp, MaterialTheme.colorScheme.primary, CircleShape)
                                    )
                                } else {
                                    Surface(
                                        shape = CircleShape,
                                        color = MaterialTheme.colorScheme.primaryContainer,
                                        modifier = Modifier
                                            .size(68.dp)
                                            .clickable {
                                                googlePhotoPickerLauncher.launch(
                                                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                                )
                                            }
                                    ) {
                                        Box(contentAlignment = Alignment.Center) {
                                            Icon(
                                                imageVector = Icons.Default.AddAPhoto,
                                                contentDescription = "Upload Photo",
                                                tint = MaterialTheme.colorScheme.onPrimaryContainer,
                                                modifier = Modifier.size(26.dp)
                                            )
                                        }
                                    }
                                }

                                Surface(
                                    shape = CircleShape,
                                    color = MaterialTheme.colorScheme.primary,
                                    shadowElevation = 2.dp,
                                    modifier = Modifier
                                        .size(24.dp)
                                        .clip(CircleShape)
                                        .clickable {
                                            googlePhotoPickerLauncher.launch(
                                                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                            )
                                        }
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(
                                            imageVector = Icons.Default.CameraAlt,
                                            contentDescription = "Choose Photo",
                                            tint = Color.White,
                                            modifier = Modifier.size(13.dp)
                                        )
                                    }
                                }
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = if (googleProfilePictureUri != null) "Photo Added" else "Add Profile Photo (Optional)",
                                fontSize = 11.sp,
                                color = if (googleProfilePictureUri != null) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    OutlinedTextField(
                        value = googleAccountName,
                        onValueChange = { googleAccountName = it },
                        label = { Text("Display Name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    OutlinedTextField(
                        value = googleStudentNumber,
                        onValueChange = { googleStudentNumber = it.uppercase() },
                        label = { Text("Student or Staff ID Number *") },
                        placeholder = { Text("e.g. STU-2026-9041") },
                        leadingIcon = { Icon(Icons.Default.Badge, contentDescription = null) },
                        singleLine = true,
                        supportingText = { Text("Required for your campus profile") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("google_student_number_input")
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    Text("Role:", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf(UserRole.STUDENT to "Student", UserRole.LECTURER to "Lecturer", UserRole.ADMIN to "Admin").forEach { (role, label) ->
                            FilterChip(
                                selected = googleRole == role,
                                onClick = { googleRole = role },
                                label = { Text(label, fontSize = 11.sp) }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    ExposedDropdownMenuBox(
                        expanded = googleCourseExpanded,
                        onExpandedChange = { googleCourseExpanded = !googleCourseExpanded },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        OutlinedTextField(
                            value = googleSelectedCourse?.courseName ?: "General / Other Faculty",
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Course / Department") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = googleCourseExpanded) },
                            modifier = Modifier.menuAnchor().fillMaxWidth()
                        )
                        ExposedDropdownMenu(
                            expanded = googleCourseExpanded,
                            onDismissRequest = { googleCourseExpanded = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("General Campus / Other Faculty") },
                                onClick = {
                                    googleSelectedCourse = null
                                    googleCourseExpanded = false
                                }
                            )
                            DropdownMenuItem(
                                text = {
                                    Text(
                                        "── NC(V) VOCATIONAL PROGRAMMES ──",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                },
                                onClick = {},
                                enabled = false
                            )
                            allCourses.filter { it.courseName.startsWith("NC(V)") }.forEach { course ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(course.courseName, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                            Text("${course.code} • ${course.department}", fontSize = 11.sp, color = MaterialTheme.colorScheme.outline)
                                        }
                                    },
                                    onClick = {
                                        googleSelectedCourse = course
                                        googleCourseExpanded = false
                                    }
                                )
                            }
                            DropdownMenuItem(
                                text = {
                                    Text(
                                        "── DEGREES & DIPLOMAS ──",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                },
                                onClick = {},
                                enabled = false
                            )
                            allCourses.filter { !it.courseName.startsWith("NC(V)") }.forEach { course ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(course.courseName, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                            Text("${course.code} • ${course.department}", fontSize = 11.sp, color = MaterialTheme.colorScheme.outline)
                                        }
                                    },
                                    onClick = {
                                        googleSelectedCourse = course
                                        googleCourseExpanded = false
                                    }
                                )
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        showGoogleCompletionDialog = false
                        viewModel.loginWithGoogleAccount(
                            email = googleAccountEmail,
                            fullName = googleAccountName,
                            studentNumber = googleStudentNumber,
                            role = googleRole,
                            courseId = googleSelectedCourse?.courseId,
                            courseName = googleSelectedCourse?.courseName,
                            department = googleSelectedCourse?.department ?: "General Campus",
                            level = googleLevel,
                            profilePictureUri = googleProfilePictureUri
                        )
                    },
                    modifier = Modifier.testTag("confirm_google_reg_button")
                ) {
                    Text("Complete Registration")
                }
            },
            dismissButton = {
                TextButton(onClick = { showGoogleCompletionDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
