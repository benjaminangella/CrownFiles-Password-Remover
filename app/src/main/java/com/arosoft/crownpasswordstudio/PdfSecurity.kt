package com.arosoft.crownpasswordstudio

import android.content.Context
import android.net.Uri
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.encryption.AccessPermission
import com.tom_roush.pdfbox.pdmodel.encryption.StandardProtectionPolicy
import com.tom_roush.pdfbox.pdmodel.encryption.InvalidPasswordException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * A local-only PDF workflow. A correct current password is required for encrypted inputs.
 * Never overwrites the source; Android's file picker creates a separate output document.
 */
internal enum class PdfAction { PROTECT, UNLOCK, CHANGE }

internal suspend fun processPdf(
    context: Context,
    source: Uri,
    destination: Uri,
    action: PdfAction,
    currentPassword: String,
    newPassword: String
): Result<Unit> = withContext(Dispatchers.IO) {
    runCatching {
        require(action == PdfAction.UNLOCK || newPassword.length >= 8) {
            "Use a new password with at least 8 characters."
        }
        context.contentResolver.openInputStream(source).use { input ->
            requireNotNull(input) { "Unable to open the selected PDF." }
            PDDocument.load(input, currentPassword).use { document ->
                if (action == PdfAction.UNLOCK) {
                    document.setAllSecurityToBeRemoved(true)
                } else {
                    val permission = AccessPermission()
                    val policy = StandardProtectionPolicy(newPassword, newPassword, permission)
                    policy.encryptionKeyLength = 256
                    policy.permissions = permission
                    document.protect(policy)
                }
                context.contentResolver.openOutputStream(destination, "w").use { output ->
                    requireNotNull(output) { "Unable to create the output PDF." }
                    document.save(output)
                }
            }
        }
    }
}
