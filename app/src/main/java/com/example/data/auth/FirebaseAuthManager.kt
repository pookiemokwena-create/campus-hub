package com.example.data.auth

import android.content.Context
import android.util.Log
import com.google.android.gms.tasks.Task
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

sealed class FirebaseVerificationResult {
    data class Success(val email: String, val isLiveFirebase: Boolean, val message: String) : FirebaseVerificationResult()
    data class Error(val message: String) : FirebaseVerificationResult()
}

class FirebaseAuthManager(private val context: Context) {

    private val tag = "FirebaseAuthManager"

    val isFirebaseInitialized: Boolean
        get() = try {
            FirebaseApp.getApps(context).isNotEmpty()
        } catch (e: Exception) {
            Log.w(tag, "FirebaseApp is not initialized: ${e.message}")
            false
        }

    private val firebaseAuth: FirebaseAuth?
        get() = if (isFirebaseInitialized) {
            try {
                FirebaseAuth.getInstance()
            } catch (e: Exception) {
                Log.w(tag, "FirebaseAuth.getInstance() failed: ${e.message}")
                null
            }
        } else null

    val currentFirebaseUser: FirebaseUser?
        get() = firebaseAuth?.currentUser

    /**
     * Registers or signs into Firebase Auth and sends an email verification link.
     */
    suspend fun sendVerificationLink(email: String, password: String): FirebaseVerificationResult {
        val auth = firebaseAuth
        if (auth == null) {
            Log.d(tag, "Firebase backend not connected (no google-services.json). Using local verification dispatch.")
            return FirebaseVerificationResult.Success(
                email = email,
                isLiveFirebase = false,
                message = "Verification link simulated for preview testing. Connect google-services.json for live Firebase delivery."
            )
        }

        return try {
            val user = try {
                val cred = auth.createUserWithEmailAndPassword(email, password).awaitTask()
                cred.user
            } catch (e: Exception) {
                // If user already exists in Firebase Auth, sign in
                val cred = auth.signInWithEmailAndPassword(email, password).awaitTask()
                cred.user
            }

            if (user != null) {
                user.sendEmailVerification().awaitTask()
                FirebaseVerificationResult.Success(
                    email = email,
                    isLiveFirebase = true,
                    message = "Firebase verification link sent successfully to $email"
                )
            } else {
                FirebaseVerificationResult.Error("Unable to obtain Firebase user account.")
            }
        } catch (e: Exception) {
            Log.e(tag, "Failed to send Firebase verification link", e)
            // Even if Firebase network throws, return clear status with message
            FirebaseVerificationResult.Error(e.localizedMessage ?: "Failed to dispatch verification email")
        }
    }

    /**
     * Resends email verification link to current user.
     */
    suspend fun resendVerificationLink(email: String): FirebaseVerificationResult {
        val auth = firebaseAuth
        if (auth == null) {
            return FirebaseVerificationResult.Success(
                email = email,
                isLiveFirebase = false,
                message = "Verification link re-sent (Simulation mode)."
            )
        }

        val user = auth.currentUser
        return if (user != null) {
            try {
                user.sendEmailVerification().awaitTask()
                FirebaseVerificationResult.Success(
                    email = email,
                    isLiveFirebase = true,
                    message = "Verification email re-sent via Firebase Auth."
                )
            } catch (e: Exception) {
                FirebaseVerificationResult.Error(e.localizedMessage ?: "Failed to resend verification email.")
            }
        } else {
            FirebaseVerificationResult.Error("No active Firebase session found. Please sign in.")
        }
    }

    /**
     * Reloads the Firebase user and checks if the email verification link has been clicked.
     */
    suspend fun checkEmailVerified(): Boolean {
        val auth = firebaseAuth ?: return false
        val user = auth.currentUser ?: return false
        return try {
            user.reload().awaitTask()
            user.isEmailVerified
        } catch (e: Exception) {
            Log.w(tag, "Failed to reload Firebase user: ${e.message}")
            false
        }
    }
}

/**
 * Coroutine extension to await Task completion safely.
 */
suspend fun <T> Task<T>.awaitTask(): T = suspendCancellableCoroutine { cont ->
    addOnSuccessListener { result ->
        if (cont.isActive) cont.resume(result)
    }
    addOnFailureListener { exception ->
        if (cont.isActive) cont.resumeWithException(exception)
    }
    addOnCanceledListener {
        if (cont.isActive) cont.cancel()
    }
}
