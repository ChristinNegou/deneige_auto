import { Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from './components/Layout';
import { useAuth } from './lib/auth';
import { DashboardPage } from './pages/DashboardPage';
import { DisputeDetailPage } from './pages/DisputeDetailPage';
import { DisputesPage } from './pages/DisputesPage';
import { LoginPage } from './pages/LoginPage';
import { ReservationDetailPage } from './pages/ReservationDetailPage';
import { ReservationsPage } from './pages/ReservationsPage';
import { SupportPage } from './pages/SupportPage';
import { UserDetailPage } from './pages/UserDetailPage';
import { UsersPage } from './pages/UsersPage';
import { VerificationDetailPage } from './pages/VerificationDetailPage';
import { VerificationsPage } from './pages/VerificationsPage';

export default function App() {
  const { user } = useAuth();
  if (!user) return <LoginPage />;

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<DashboardPage />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="users/:id" element={<UserDetailPage />} />
        <Route path="reservations" element={<ReservationsPage />} />
        <Route path="reservations/:id" element={<ReservationDetailPage />} />
        <Route path="disputes" element={<DisputesPage />} />
        <Route path="disputes/:id" element={<DisputeDetailPage />} />
        <Route path="verifications" element={<VerificationsPage />} />
        <Route path="verifications/:id" element={<VerificationDetailPage />} />
        <Route path="support" element={<SupportPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
