const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET;

app.use(cors());
app.use(express.json());

const deviceDetailsInclude = {
  deviceType: true,
  location: true,
  inspections: {
    orderBy: { inspectedAt: 'asc' },
    include: {
      technician: {
        include: { role: true }
      },
      images: true
    }
  }
};

const serializeUser = (user) => ({
  id: user.id,
  firstName: user.firstName,
  lastName: user.lastName,
  fullName: user.fullName,
  email: user.email,
  username: user.username,
  region: user.region,
  status: user.status,
  role: user.role ? { id: user.role.id, name: user.role.name } : undefined
});

const serializeDevice = (device) => ({
  id: device.id,
  deviceCode: device.deviceCode,
  deviceName: device.deviceName,
  barcode: device.barcode,
  serialNumber: device.serialNumber,
  ipAddress: device.ipAddress,
  firmware: device.firmware,
  excelDate: device.excelDate,
  excelStatus: device.excelStatus,
  manufacturer: device.manufacturer,
  modelNumber: device.modelNumber,
  currentStatus: device.currentStatus,
  installDate: device.installDate,
  lastInspectionAt: device.lastInspectionAt,
  notes: device.notes,
  deviceType: device.deviceType,
  location: device.location,
  inspections: (device.inspections || []).map((inspection) => ({
    id: inspection.id,
    inspectionStatus: inspection.inspectionStatus,
    issueReason: inspection.issueReason,
    notes: inspection.notes,
    latitude: inspection.latitude,
    longitude: inspection.longitude,
    locationText: inspection.locationText,
    inspectedAt: inspection.inspectedAt,
    technician: inspection.technician ? serializeUser(inspection.technician) : null,
    images: (inspection.images || []).map((image) => ({
      id: image.id,
      imageUrl: image.imageUrl,
      imageType: image.imageType
    }))
  }))
});

const buildDeviceSearchWhere = (rawValue) => {
  const value = (rawValue || '').trim();
  if (!value) {
    return null;
  }

  return {
    OR: [
      { barcode: { equals: value, mode: 'insensitive' } },
      { deviceCode: { equals: value, mode: 'insensitive' } },
      { serialNumber: { equals: value, mode: 'insensitive' } },
      { ipAddress: { equals: value, mode: 'insensitive' } },
      { deviceName: { contains: value, mode: 'insensitive' } },
      { manufacturer: { contains: value, mode: 'insensitive' } },
      { modelNumber: { contains: value, mode: 'insensitive' } }
    ]
  };
};

// Middleware for authentication
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Access token required' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid token' });
    req.user = user;
    next();
  });
};

// Middleware for role-based access
const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Insufficient permissions' });
    }
    next();
  };
};

// Auth routes
app.post('/api/auth/login', async (req, res) => {
  const { email, password, role } = req.body;
  if (!email || !password || !role) {
    return res.status(400).json({ message: 'Email, password and role are required' });
  }

  try {
    const user = await prisma.user.findUnique({
      where: { email },
      include: { role: true }
    });
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });
    if (user.status !== 'ACTIVE') return res.status(403).json({ message: 'Account is inactive' });
    if (user.role.name.toLowerCase() !== role.toLowerCase()) {
      return res.status(403).json({ message: 'Selected role does not match user role' });
    }

    const isValidPassword = await bcrypt.compare(
      password,
      user.passwordHash || user.password
    );
    if (!isValidPassword) return res.status(401).json({ message: 'Invalid credentials' });

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role.name },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        role: user.role.name
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/auth/me', authenticateToken, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: { role: true }
    });
    res.json({
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      role: user.role.name
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/auth/change-password', authenticateToken, async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    const isValidPassword = await bcrypt.compare(
      oldPassword,
      user.passwordHash || user.password
    );
    if (!isValidPassword) return res.status(400).json({ message: 'Old password is incorrect' });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.user.update({
      where: { id: req.user.id },
      data: { passwordHash: hashedPassword }
    });
    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Roles routes
app.get('/api/roles', authenticateToken, async (req, res) => {
  try {
    const roles = await prisma.role.findMany();
    res.json(roles.map(role => role.name));
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Users routes (Admin only)
app.post('/api/users', authenticateToken, authorizeRoles('ADMIN'), async (req, res) => {
  const { firstName, lastName, fullName, email, username, password, phone, jobTitle, region, roleId } = req.body;
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: {
        firstName,
        lastName,
        fullName,
        email,
        username,
        passwordHash: hashedPassword,
        phone,
        jobTitle,
        region,
        roleId
      },
      include: { role: true }
    });
    res.status(201).json(user);
  } catch (error) {
    if (error.code === 'P2002') {
      res.status(409).json({ message: 'Email or username already exists' });
    } else {
      res.status(500).json({ message: 'Server error' });
    }
  }
});

app.get('/api/users', authenticateToken, authorizeRoles('ADMIN'), async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      include: { role: true }
    });
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/users/:id', authenticateToken, authorizeRoles('ADMIN'), async (req, res) => {
  const { id } = req.params;
  try {
    const user = await prisma.user.findUnique({
      where: { id: parseInt(id) },
      include: { role: true }
    });
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

app.put('/api/users/:id', authenticateToken, authorizeRoles('ADMIN'), async (req, res) => {
  const { id } = req.params;
  const { firstName, lastName, fullName, email, username, phone, jobTitle, region, roleId } = req.body;
  try {
    const user = await prisma.user.update({
      where: { id: parseInt(id) },
      data: {
        firstName,
        lastName,
        fullName,
        email,
        username,
        phone,
        jobTitle,
        region,
        roleId
      },
      include: { role: true }
    });
    res.json(user);
  } catch (error) {
    if (error.code === 'P2002') {
      res.status(409).json({ message: 'Email or username already exists' });
    } else {
      res.status(500).json({ message: 'Server error' });
    }
  }
});

app.patch('/api/users/:id/status', authenticateToken, authorizeRoles('ADMIN'), async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  try {
    const user = await prisma.user.update({
      where: { id: parseInt(id) },
      data: { status }
    });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

app.delete('/api/users/:id', authenticateToken, authorizeRoles('ADMIN'), async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.user.delete({
      where: { id: parseInt(id) }
    });
    res.json({ message: 'User deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/devices/barcode', authenticateToken, async (req, res) => {
  const value =
    req.query.serialNumber ||
    req.query.barcode ||
    req.query.code ||
    req.query.deviceCode ||
    req.query.q;

  const where = buildDeviceSearchWhere(value);
  if (!where) {
    return res.status(400).json({ message: 'Search value is required' });
  }

  try {
    const device = await prisma.device.findFirst({
      where,
      include: deviceDetailsInclude
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    res.json(serializeDevice(device));
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/devices/barcode/:value', authenticateToken, async (req, res) => {
  const where = buildDeviceSearchWhere(req.params.value);
  if (!where) {
    return res.status(400).json({ message: 'Search value is required' });
  }

  try {
    const device = await prisma.device.findFirst({
      where,
      include: deviceDetailsInclude
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    res.json(serializeDevice(device));
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/devices/:id', authenticateToken, async (req, res) => {
  const id = Number(req.params.id);
  if (Number.isNaN(id)) {
    return res.status(400).json({ message: 'Invalid device id' });
  }

  try {
    const device = await prisma.device.findUnique({
      where: { id },
      include: deviceDetailsInclude
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    res.json(serializeDevice(device));
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Seed initial data
const seedData = async () => {
  try {
    const adminRole = await prisma.role.upsert({
      where: { name: 'ADMIN' },
      update: {},
      create: { name: 'ADMIN' }
    });
    const viewerRole = await prisma.role.upsert({
      where: { name: 'VIEWER' },
      update: {},
      create: { name: 'VIEWER' }
    });
    const technicianRole = await prisma.role.upsert({
      where: { name: 'TECHNICIAN' },
      update: {},
      create: { name: 'TECHNICIAN' }
    });

    const hashedPassword = await bcrypt.hash('admin123', 10);
    await prisma.user.upsert({
      where: { email: 'admin@example.com' },
      update: {},
      create: {
        firstName: 'Admin',
        lastName: 'User',
        fullName: 'Admin User',
        email: 'admin@example.com',
        username: 'admin',
        passwordHash: hashedPassword,
        roleId: adminRole.id
      }
    });

    console.log('Seeded initial data');
  } catch (error) {
    console.error('Error seeding data:', error);
  }
};

app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await seedData();
});
