import multer from 'multer';
import CloudinaryStorage from 'multer-storage-cloudinary';
import cloudinaryPackage from 'cloudinary'; // paquete completo, con .v2 adentro
import '../utils/cloudinary.js'; // solo para que se ejecute cloudinary.config(...) antes de usarlo aquí

const crearUploadMiddleware = (carpeta) => {
  const storage = new CloudinaryStorage({
    cloudinary: cloudinaryPackage,
    params: {
      folder: `fitzone/${carpeta}`,
      allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
      transformation: [{ width: 800, height: 800, crop: 'limit' }]
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