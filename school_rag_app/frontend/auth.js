/**
 * Mock Authentication Module using LocalStorage
 */

const Auth = {
    // Current valid roles
    ROLES: {
        ADMIN: 'Admin',
        STUDENT: 'Student'
    },

    // Initialize mock database
    init() {
        if (!localStorage.getItem('mock_users')) {
            localStorage.setItem('mock_users', JSON.stringify([]));
        }
    },

    // Register a new user
    register(username, password, role) {
        this.init();
        const users = JSON.parse(localStorage.getItem('mock_users'));

        if (users.find(u => u.username === username)) {
            return { success: false, message: 'Username already exists' };
        }

        users.push({ username, password, role });
        localStorage.setItem('mock_users', JSON.stringify(users));

        // Auto-login after register
        this.setSession(username, role);
        return { success: true };
    },

    // Login user
    login(username, password) {
        this.init();
        const users = JSON.parse(localStorage.getItem('mock_users'));
        const user = users.find(u => u.username === username && u.password === password);

        if (user) {
            this.setSession(user.username, user.role);
            return { success: true, role: user.role };
        }

        return { success: false, message: 'Invalid username or password' };
    },

    // Set current active session
    setSession(username, role) {
        const session = { username, role };
        localStorage.setItem('current_session', JSON.stringify(session));
    },

    // Get current session
    getSession() {
        const session = localStorage.getItem('current_session');
        return session ? JSON.parse(session) : null;
    },

    // Logout
    logout() {
        localStorage.removeItem('current_session');
        window.location.href = 'login.html';
    },

    // Protect standard routes (Requires Login)
    requireLogin() {
        const session = this.getSession();
        if (!session) {
            window.location.replace('login.html');
            return false;
        }
        return session;
    },

    // Protect admin routes (Requires Admin role)
    requireAdmin() {
        const session = this.requireLogin();
        if (session && session.role !== this.ROLES.ADMIN) {
            alert('Bạn không có quyền truy cập vào trang dành cho Admin.');
            window.location.replace('index.html');
            return false;
        }
        return session;
    },

    // Check if logged in & redirect accordingly (used on login/register pages)
    redirectIfLoggedIn() {
        const session = this.getSession();
        if (session) {
            if (session.role === this.ROLES.ADMIN) {
                window.location.replace('admin.html');
            } else {
                window.location.replace('index.html');
            }
        }
    }
};

// Auto-initialize when file loads
Auth.init();
