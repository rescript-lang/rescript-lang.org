export default {
  dir: "public", // Directory to scan for images
  converted: "*.{png,jpg,jpeg}", // Glob pattern for source image files to convert
  format: "avif", // Output image format: 'webp' or 'avif'
  quality: 80, // Quality of output images (0–100)
  recursive: true, // Whether to search subdirectories recursively
  removeOriginal: true, // Delete original files after successful conversion
  ignoreOnStart: false, // If true, ignore existing files on watcher startup
};
