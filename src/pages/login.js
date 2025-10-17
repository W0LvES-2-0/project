import { supabase } from '../lib/supabase.js';
import { navigateTo } from '../lib/router.js';

export function LoginPage() {
  return `
    <div class="auth-container">
      <div class="auth-card">
        <h1>Login</h1>
        <form id="loginForm" class="auth-form">
          <div class="form-group">
            <label for="email">Email</label>
            <input type="email" id="email" name="email" required autocomplete="email">
          </div>
          <div class="form-group">
            <label for="password">Password</label>
            <input type="password" id="password" name="password" required autocomplete="current-password">
          </div>
          <div id="loginError" class="error-message" style="display: none;"></div>
          <button type="submit" class="btn btn-primary" id="loginBtn">
            Login
          </button>
        </form>
        <p class="auth-link">
          Don't have an account? <a href="/signup" data-link>Sign up</a>
        </p>
      </div>
    </div>
  `;
}

export function setupLoginPage() {
  const form = document.getElementById('loginForm');
  const errorDiv = document.getElementById('loginError');
  const loginBtn = document.getElementById('loginBtn');

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    errorDiv.style.display = 'none';
    loginBtn.disabled = true;
    loginBtn.textContent = 'Logging in...';

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      errorDiv.textContent = error.message;
      errorDiv.style.display = 'block';
      loginBtn.disabled = false;
      loginBtn.textContent = 'Login';
    } else {
      navigateTo('/');
    }
  });
}
