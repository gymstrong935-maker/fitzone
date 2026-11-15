import multer from 'multer';
import CloudinaryStorage from 'multer-storage-cloudinary';
import { v2 as cloudinary } from 'cloudinary';
import '../utils/cloudinary.js'; // ejecuta cloudinary.config(...) antes de usarlo aquí

const crearUploadMiddleware = (carpeta, { maxLado = 800 } = {}) => {
  const storage = new CloudinaryStorage({
    // multer-storage-cloudinary 2.x llama a `cloudinary.v2.uploader...`, así que necesita un
    // objeto con la propiedad `v2` (el paquete completo), NO el objeto v2 directamente.
    // Pasar `cloudinary` (v2) a secas hace que el servidor se caiga con
    // "Cannot read properties of undefined (reading 'uploader')" al subir cualquier imagen.
    cloudinary: { v2: cloudinary },
    params: {
      folder: `fitzone/${carpeta}`,
      allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
      transformation: [{ width: maxLado, height: maxLado, crop: 'limit' }]
    }
  });

  return multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
      if (!file.mimetype.startsWith('image/')) {
        return cb(new Error('Solo se permiten archivos de imagen'), false);
      }
      cb(null, true);
    }
  });
};

export default crearUploadMiddleware;