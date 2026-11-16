package com.arosoft.crownpasswordstudio

import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import kotlinx.coroutines.launch
import java.util.Locale

private val Navy = Color(0xFF102D63)
private val Blue = Color(0xFF1158CB)
private val Gold = Color(0xFFD5A122)
private val Canvas = Color(0xFFF5F8FE)
private val Ink = Color(0xFF17263E)
private val Soft = Color(0xFF63738B)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        PDFBoxResourceLoader.init(applicationContext)
        setContent { CrownApp() }
    }
}

private enum class Screen { HOME, TOOLS, FILE }
private enum class Operation(val display: String, val icon: ImageVector) {
    PROTECT("Protect File", Icons.Outlined.Lock),
    UNLOCK("Unlock File", Icons.Outlined.LockOpen),
    CHANGE("Change Password", Icons.Outlined.Key),
    BATCH("Batch Tools", Icons.Outlined.Layers),
    CHECK("Security Check", Icons.Outlined.VerifiedUser)
}

@Composable
private fun CrownApp() {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var screen by remember { mutableStateOf(Screen.HOME) }
    var operation by remember { mutableStateOf(Operation.PROTECT) }
    var selectedUri by remember { mutableStateOf<Uri?>(null) }
    var selectedName by remember { mutableStateOf("") }
    var existingPassword by remember { mutableStateOf("") }
    var newPassword by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf("") }

    fun clearPasswords() {
        existingPassword = ""
        newPassword = ""
        confirmPassword = ""
    }
    fun startOperation(op: Operation) {
        operation = op
        selectedUri = null
        selectedName = ""
        clearPasswords()
        message = ""
        screen = Screen.FILE
    }

    val pickFile = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        selectedUri = uri
        selectedName = uri?.let { picked ->
            context.contentResolver.query(picked, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) cursor.getString(0) else null
                } ?: "Selected file"
        } ?: ""
        message = ""
    }

    val saveFile = rememberLauncherForActivityResult(
        ActivityResultContracts.CreateDocument("application/pdf")
    ) { destination ->
        val input = selectedUri
        if (destination == null || input == null) return@rememberLauncherForActivityResult
        val pdfOperation = when (operation) {
            Operation.PROTECT -> PdfAction.PROTECT
            Operation.UNLOCK -> PdfAction.UNLOCK
            Operation.CHANGE -> PdfAction.CHANGE
            else -> return@rememberLauncherForActivityResult
        }
        busy = true
        scope.launch {
            val result = processPdf(
                context, input, destination, pdfOperation, existingPassword, newPassword
            )
            clearPasswords()
            busy = false
            message = result.fold(
                onSuccess = { "Saved securely as a new PDF file." },
                onFailure = { "Unable to process file: ${it.message ?: "Unsupported or incorrect password."}" }
            )
        }
    }

    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = Blue, onPrimary = Color.White,
            background = Canvas, surface = Color.White,
            onSurface = Ink
        )
    ) {
        Scaffold(
            containerColor = Canvas,
            bottomBar = {
                NavigationBar(containerColor = Color.White) {
                    NavigationBarItem(
                        selected = screen == Screen.HOME,
                        onClick = { clearPasswords(); screen = Screen.HOME },
                        icon = { Icon(Icons.Outlined.Home, "Home") },
                        label = { Text("Home") }
                    )
                    NavigationBarItem(
                        selected = screen == Screen.FILE,
                        onClick = { startOperation(Operation.PROTECT) },
                        icon = { Icon(Icons.Outlined.FolderOpen, "Files") },
                        label = { Text("Files") }
                    )
                    NavigationBarItem(
                        selected = screen == Screen.TOOLS,
                        onClick = { clearPasswords(); screen = Screen.TOOLS },
                        icon = { Icon(Icons.Outlined.GridView, "Tools") },
                        label = { Text("Tools") }
                    )
                }
            }
        ) { padding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
            ) {
                Header(screen) { screen = Screen.HOME; clearPasswords() }
                when (screen) {
                    Screen.HOME -> {
                        Spacer(Modifier.height(24.dp))
                        Column(Modifier.padding(horizontal = 20.dp)) {
                            Text("What would you like to do?", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Ink)
                            Spacer(Modifier.height(16.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                                HomeTile("Unlock File", Icons.Outlined.LockOpen, Modifier.weight(1f)) {
                                    startOperation(Operation.UNLOCK)
                                }
                                HomeTile("Protect File", Icons.Outlined.Lock, Modifier.weight(1f)) {
                                    startOperation(Operation.PROTECT)
                                }
                            }
                            Spacer(Modifier.height(14.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                                HomeTile("Change Password", Icons.Outlined.Key, Modifier.weight(1f)) {
                                    startOperation(Operation.CHANGE)
                                }
                                HomeTile("Batch Tools", Icons.Outlined.Layers, Modifier.weight(1f)) {
                                    startOperation(Operation.BATCH)
                                }
                            }
                            Spacer(Modifier.height(14.dp))
                            Surface(
                                onClick = { startOperation(Operation.CHECK) },
                                shape = RoundedCornerShape(18.dp),
                                color = Color.White,
                                border = BorderStroke(1.dp, Color(0xFFE3E9F2)),
                                shadowElevation = 1.dp
                            ) {
                                Row(Modifier.fillMaxWidth().padding(19.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Outlined.VerifiedUser, null, tint = Blue)
                                    Spacer(Modifier.width(16.dp))
                                    Text("File Security Check", fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                                    Icon(Icons.Outlined.ChevronRight, null, tint = Soft)
                                }
                            }
                            Spacer(Modifier.height(20.dp))
                            Text("Excel  •  Word  •  PowerPoint  •  PDF", color = Soft, fontSize = 12.sp, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
                        }
                    }
                    Screen.TOOLS -> {
                        Column(
                            Modifier.padding(horizontal = 20.dp, vertical = 22.dp),
                            verticalArrangement = Arrangement.spacedBy(14.dp)
                        ) {
                            Text("Choose file type", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Ink)
                            ToolRow("Excel Tools", "Sheets & workbooks", "X", Color(0xFF178650)) { startOperation(Operation.CHECK) }
                            ToolRow("Word Tools", "Documents & templates", "W", Color(0xFF2469D7)) { startOperation(Operation.CHECK) }
                            ToolRow("PowerPoint Tools", "Slides & presentations", "P", Color(0xFFE46D28)) { startOperation(Operation.CHECK) }
                            ToolRow("PDF Security", "Protect & unlock PDFs", "PDF", Color(0xFFCF2637)) { startOperation(Operation.PROTECT) }
                        }
                    }
                    Screen.FILE -> {
                        Column(
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 22.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Text(operation.display, fontSize = 23.sp, fontWeight = FontWeight.Bold, color = Ink)
                            OutlinedButton(
                                onClick = { pickFile.launch(arrayOf("application/pdf", "application/octet-stream", "application/vnd.openxmlformats-officedocument.*", "*/*")) },
                                modifier = Modifier.fillMaxWidth().height(58.dp),
                                shape = RoundedCornerShape(14.dp)
                            ) {
                                Icon(Icons.Outlined.FileOpen, null)
                                Spacer(Modifier.width(10.dp))
                                Text(if (selectedUri == null) "Choose a file" else selectedName, maxLines = 1)
                            }
                            if (selectedUri != null) {
                                if (!selectedName.lowercase(Locale.ROOT).endsWith(".pdf")) {
                                    Surface(shape = RoundedCornerShape(16.dp), color = Color.White) {
                                        Text(
                                            "Office file detected. Office password operations are not available in this first release. PDF security is ready.",
                                            modifier = Modifier.padding(18.dp),
                                            color = Soft
                                        )
                                    }
                                } else if (operation == Operation.CHECK || operation == Operation.BATCH) {
                                    Text("This action is planned for a later release.", color = Soft)
                                } else {
                                    if (operation != Operation.PROTECT) {
                                        OutlinedTextField(
                                            value = existingPassword,
                                            onValueChange = { existingPassword = it },
                                            label = { Text("Current password") },
                                            visualTransformation = PasswordVisualTransformation(),
                                            singleLine = true,
                                            modifier = Modifier.fillMaxWidth()
                                        )
                                    }
                                    if (operation != Operation.UNLOCK) {
                                        OutlinedTextField(
                                            value = newPassword,
                                            onValueChange = { newPassword = it },
                                            label = { Text("New password") },
                                            visualTransformation = PasswordVisualTransformation(),
                                            singleLine = true,
                                            modifier = Modifier.fillMaxWidth()
                                        )
                                        OutlinedTextField(
                                            value = confirmPassword,
                                            onValueChange = { confirmPassword = it },
                                            label = { Text("Confirm new password") },
                                            visualTransformation = PasswordVisualTransformation(),
                                            singleLine = true,
                                            modifier = Modifier.fillMaxWidth()
                                        )
                                    }
                                    val valid = when (operation) {
                                        Operation.PROTECT -> newPassword.length >= 8 && newPassword == confirmPassword
                                        Operation.CHANGE -> existingPassword.isNotEmpty() && newPassword.length >= 8 && newPassword == confirmPassword
                                        Operation.UNLOCK -> existingPassword.isNotEmpty()
                                        else -> false
                                    }
                                    Button(
                                        onClick = {
                                            val suffix = when (operation) {
                                                Operation.UNLOCK -> "unlocked"
                                                Operation.PROTECT -> "protected"
                                                else -> "updated"
                                            }
                                            saveFile.launch(selectedName.removeSuffix(".pdf") + "-$suffix.pdf")
                                        },
                                        enabled = valid && !busy,
                                        modifier = Modifier.fillMaxWidth().height(54.dp),
                                        shape = RoundedCornerShape(14.dp)
                                    ) {
                                        Text(if (busy) "Processing…" else operation.display)
                                    }
                                }
                            }
                            if (message.isNotBlank()) Text(message, color = if (message.startsWith("Saved")) Color(0xFF187849) else Color(0xFFA23F36))
                            Text("Files are processed on your device. A valid current password is required to unlock encrypted files.", color = Soft, fontSize = 12.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Header(screen: Screen, onBack: () -> Unit) {
    Column(Modifier.fillMaxWidth().background(Navy).padding(horizontal = 22.dp, vertical = 22.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (screen != Screen.HOME) {
                IconButton(onClick = onBack) { Icon(Icons.Outlined.ArrowBack, "Back", tint = Color.White) }
            } else {
                Icon(Icons.Outlined.Lock, null, tint = Gold, modifier = Modifier.size(31.dp))
            }
            Spacer(Modifier.width(10.dp))
            Text("Crown Password Studio", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = Color.White, modifier = Modifier.weight(1f))
        }
        if (screen == Screen.HOME) {
            Spacer(Modifier.height(9.dp))
            Text("Office & PDF Security", color = Color(0xFFD6E4FF), fontSize = 13.sp)
        }
    }
}

@Composable
private fun HomeTile(title: String, icon: ImageVector, modifier: Modifier, onClick: () -> Unit) {
    Surface(
        onClick = onClick, modifier = modifier.height(145.dp),
        shape = RoundedCornerShape(20.dp),
        color = Color.White, border = BorderStroke(1.dp, Color(0xFFE3E9F2)),
        shadowElevation = 2.dp
    ) {
        Column(
            Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(icon, null, modifier = Modifier.size(36.dp), tint = Blue)
            Spacer(Modifier.height(15.dp))
            Text(title, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center, color = Ink)
        }
    }
}

@Composable
private fun ToolRow(title: String, subtitle: String, letter: String, color: Color, onClick: () -> Unit) {
    Surface(onClick = onClick, color = Color.White, shape = RoundedCornerShape(18.dp), border = BorderStroke(1.dp, Color(0xFFE3E9F2))) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(Modifier.size(48.dp).background(color, RoundedCornerShape(12.dp)), contentAlignment = Alignment.Center) {
                Text(letter, color = Color.White, fontWeight = FontWeight.ExtraBold, fontSize = if (letter == "PDF") 15.sp else 25.sp)
            }
            Spacer(Modifier.width(16.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold, color = Ink)
                Text(subtitle, fontSize = 12.sp, color = Soft)
            }
            Icon(Icons.Outlined.ChevronRight, null, tint = Soft)
        }
    }
}
