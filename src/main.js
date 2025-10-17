import { router, navigateTo } from './lib/router.js';
import { supabase } from './lib/supabase.js';
import { renderHome } from './pages/home.js';
import { renderFirmware } from './pages/firmware.js';
import { renderDeviceList } from './pages/devices.js';
import { renderProjectList } from './pages/projects.js';
import { renderProjectDetail } from './pages/project-detail.js';
import { renderDeviceTelemetry } from './pages/device-telemetry.js';
import { renderProjectTelemetry } from './pages/project-telemetry.js';
import { renderMLScriptEditor } from './pages/ml-script-editor.js';
import { renderRealtimeData } from './pages/realtime-data.js';
import { LoginPage, setupLoginPage } from './pages/login.js';
import { SignupPage, setupSignupPage } from './pages/signup.js';
import './lib/device-manager.js';

window.router = router;

let currentUser = null;

supabase.auth.getSession().then(({ data: { session } }) => {
  currentUser = session?.user || null;
  initApp();
});

supabase.auth.onAuthStateChange((async (event, session) => {
  currentUser = session?.user || null;

  if (event === 'SIGNED_IN') {
    navigateTo('/');
  } else if (event === 'SIGNED_OUT') {
    navigateTo('/login');
  }
}));

function requireAuth(handler) {
  return (...args) => {
    if (!currentUser) {
      navigateTo('/login');
      return;
    }
    handler(...args);
  };
}

function renderPage(pageFunction, setupFunction) {
  return () => {
    const content = pageFunction();
    document.getElementById('app').innerHTML = content;
    if (setupFunction) {
      setupFunction();
    }
  };
}

router.register('/login', renderPage(LoginPage, setupLoginPage));
router.register('/signup', renderPage(SignupPage, setupSignupPage));
router.register('/', requireAuth(renderHome));
router.register('/firmware', requireAuth(renderFirmware));
router.register('/devices', requireAuth(renderDeviceList));
router.register('/device/telemetry', requireAuth(renderDeviceTelemetry));
router.register('/device/realtime', requireAuth(renderRealtimeData));
router.register('/projects', requireAuth(renderProjectList));
router.register('/project', requireAuth(renderProjectDetail));
router.register('/project/telemetry', requireAuth((params) => renderProjectTelemetry(params.get('id'))));
router.register('/project/ml-script', requireAuth(renderMLScriptEditor));

function initApp() {
  router.init();
}
