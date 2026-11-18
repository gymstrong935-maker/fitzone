import dns from 'node:dns';

// DNS públicos para evitar problemas con consultas SRV
// de MongoDB Atlas en determinadas redes.
dns.setServers(['8.8.8.8', '8.8.4.4']);
