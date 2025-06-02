package FiNe

import kotlinx.coroutines.*
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaPlugin
import org.json.JSONArray
import java.io.*
import java.net.URL
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

class Zeep : CordovaPlugin() {

    private val bufferSize = 32 * 1024 // 32KB

    override fun execute(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean {
        val from = args.getString(0)
        val to = args.getString(1)

        CoroutineScope(Dispatchers.IO).launch {
            try {
                when (action) {
                    "zip" -> zip(File(resolvePath(from)), File(resolvePath(to)))
                    "unzip" -> unzipInParallel(File(resolvePath(from)), File(resolvePath(to)))
                    else -> {
                        callbackContext.error("Unsupported action: $action")
                        return@launch
                    }
                }
                withContext(Dispatchers.Main) {
                    callbackContext.success("✅ $action completed.")
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callbackContext.error("❌ Error: ${e.message}")
                }
            }
        }
        return true
    }

    private fun zip(fromDir: File, toZip: File) {
        ZipOutputStream(BufferedOutputStream(FileOutputStream(toZip), bufferSize)).use { zipOut ->
            walkZip(zipOut, fromDir, fromDir)
        }
    }

    private fun walkZip(zipOut: ZipOutputStream, root: File, current: File) {
        current.listFiles()?.forEach { file ->
            if (file.isDirectory) {
                walkZip(zipOut, root, file)
            } else {
                FileInputStream(file).use { input ->
                    val entryName = root.toURI().relativize(file.toURI()).path
                    zipOut.putNextEntry(ZipEntry(entryName))
                    input.copyTo(zipOut, bufferSize)
                    zipOut.closeEntry()
                }
            }
        }
    }

    private suspend fun unzipInParallel(zipFile: File, destDir: File) = withContext(Dispatchers.IO) {
        val tasks = mutableListOf<Deferred<Unit>>()
        ZipInputStream(BufferedInputStream(FileInputStream(zipFile), bufferSize)).use { zis ->
            var entry: ZipEntry? = zis.nextEntry
            while (entry != null) {
                val currentEntry = entry
                val outputFile = File(destDir, currentEntry.name)
                val canonicalTarget = destDir.canonicalPath
                val canonicalOut = outputFile.canonicalPath

                if (!canonicalOut.startsWith(canonicalTarget)) {
                    throw SecurityException("Zip Path Traversal detected: ${currentEntry.name}")
                }

                if (currentEntry.isDirectory) {
                    outputFile.mkdirs()
                } else {
                    outputFile.parentFile?.mkdirs()

                    // Read content into memory (ZipInputStream is not thread-safe)
                    val entryData = ByteArrayOutputStream().use { bufferOut ->
                        zis.copyTo(bufferOut, bufferSize)
                        bufferOut.toByteArray()
                    }

                    val task = async {
                        BufferedOutputStream(FileOutputStream(outputFile), bufferSize).use { out ->
                            out.write(entryData)
                        }
                    }
                    tasks.add(task)
                }

                entry = zis.nextEntry
            }
        }

        tasks.awaitAll()
    }

    private fun resolvePath(pathOrUrl: String): String {
        return try {
            File(URL(pathOrUrl).toURI()).absolutePath
        } catch (e: Exception) {
            pathOrUrl
        }
    }
}
