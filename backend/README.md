# Access Track Backend

Backend API for Access Track application with role-based authentication.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Set up PostgreSQL database and update `.env` with correct DATABASE_URL.

3. Run migrations:
   ```bash
   npx prisma migrate dev --name init
   ```

4. Generate Prisma client:
   ```bash
   npx prisma generate
   ```

5. Start the server:
   ```bash
   npm run dev
   ```

## API Endpoints

### Authentication
- POST /api/auth/login - Login with email and password
- GET /api/auth/me - Get current user info
- POST /api/auth/change-password - Change password

### Roles
- GET /api/roles - Get all roles (admin, viewer, technician)

### Users (Admin only)
- POST /api/users - Create user
- GET /api/users - Get all users
- GET /api/users/:id - Get user by ID
- PUT /api/users/:id - Update user
- PATCH /api/users/:id/status - Activate/deactivate user
- DELETE /api/users/:id - Delete user

## Roles and Permissions

- **Admin**: Full access to all endpoints
- **Viewer**: Read-only access (not implemented yet)
- **Technician**: Limited access (not implemented yet)

## Testing

Use Postman or similar to test the APIs.

Example login:
```json
{
  "email": "admin@example.com",
  "password": "admin123"
}
```

## Notes

- Initial admin user is seeded with email: admin@example.com, password: admin123
- JWT tokens expire in 24 hours
- Passwords are hashed using bcrypt