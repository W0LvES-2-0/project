import { supabase } from '../lib/supabase.js';
import { navigateTo } from '../lib/router.js';

export function SignupPage() {
  return `
    <div class="auth-container">
      <div class="auth-card">
        <h1>Sign Up</h1>
        <form id="signupForm" class="auth-form">
          <div class="form-group">
            <label for="email">Email</label>
            <input type="email" id="email" name="email" required autocomplete="email">
          </div>
          <div class="form-group">
            <label for="displayName">Display Name</label>
            <input type="text" id="displayName" name="displayName" autocomplete="name">
          </div>
          <div class="form-group">
            <label for="password">Password</label>
            <input type="password" id="password" name="password" required minlength="6" autocomplete="new-password">
          </div>
          <div class="form-group">
            <label for="confirmPassword">Confirm Password</label>
            <input type="password" id="confirmPassword" name="confirmPassword" required minlength="6" autocomplete="new-password">
          </div>
          <div id="signupError" class="error-message" style="display: none;"></div>
          <button type="submit" class="btn btn-primary" id="signupBtn">
            Sign Up
          </button>
        </form>
        <p class="auth-link">
          Already have an account? <a href="/login" data-link>Login</a>
        </p>
      </div>
    </div>
  `;
}

export function setupSignupPage() {
  const form = document.getElementById('signupForm');
  const errorDiv = document.getElementById('signupError');
  const signupBtn = document.getElementById('signupBtn');

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    errorDiv.style.display = 'none';

    const email = document.getElementById('email').value;
    const displayName = document.getElementById('displayName').value;
    const password = document.getElementById('password').value;
    const confirmPassword = document.getElementById('confirmPassword').value;

    if (password !== confirmPassword) {
      errorDiv.textContent = 'Passwords do not match';
      errorDiv.style.display = 'block';
      return;
    }

    signupBtn.disabled = true;
    signupBtn.textContent = 'Signing up...';

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
    });

    if (authError) {
      errorDiv.textContent = authError.message;
      errorDiv.style.display = 'block';
      signupBtn.disabled = false;
      signupBtn.textContent = 'Sign Up';
      return;
    }

    if (authData.user) {
      const { error: profileError } = await supabase
        .from('user_profiles')
        .insert([
          {
            user_id: authData.user.id,
            email: email,
            display_name: displayName || email.split('@')[0],
          },
        ]);

      if (profileError) {
        console.error('Error creating profile:', profileError);
      }

      navigateTo('/');
    }
  });
}
