import { NavLink, Outlet } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import clsx from 'clsx';
import { BellRing, CalendarCheck, CreditCard, Gavel, HardHat, LayoutDashboard, LifeBuoy, LogOut, ShieldCheck, Snowflake, Users, Wallet } from 'lucide-react';
import type { ReactNode } from 'react';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth';

/** Compteurs de la barre laterale : ce qui attend une action de l'admin. */
function useQueueCounts() {
  const verifications = useQuery({
    queryKey: ['verifications', 'stats'],
    queryFn: () => api<{ data: { pending: number } }>('/admin/verifications/stats'),
    refetchInterval: 60_000,
  });
  const disputes = useQuery({
    queryKey: ['disputes', 'stats'],
    queryFn: () => api<{ stats: { pendingCount: number } }>('/disputes/admin/stats'),
    refetchInterval: 60_000,
  });
  const support = useQuery({
    queryKey: ['support', 'pending-count'],
    queryFn: () => api<{ total: number }>('/support/requests', { query: { status: 'pending', limit: 1 } }),
    refetchInterval: 60_000,
  });
  return {
    verifications: verifications.data?.data.pending ?? 0,
    disputes: disputes.data?.stats.pendingCount ?? 0,
    support: support.data?.total ?? 0,
  };
}

function NavItem({ to, icon, label, count }: { to: string; icon: ReactNode; label: string; count?: number }) {
  return (
    <NavLink
      to={to}
      end={to === '/'}
      className={({ isActive }) =>
        clsx(
          'flex items-center gap-3 rounded-lg px-3 py-2 font-semibold transition-colors',
          isActive ? 'bg-white/10 text-white' : 'text-white/65 hover:bg-white/5 hover:text-white',
        )
      }
    >
      {icon}
      <span className="flex-1">{label}</span>
      {!!count && (
        <span className="tabular rounded-full bg-signal px-2 py-0.5 text-xs font-extrabold text-white" aria-label={`${count} en attente`}>
          {count}
        </span>
      )}
    </NavLink>
  );
}

export function Layout() {
  const { user, logout } = useAuth();
  const counts = useQueueCounts();
  const iconClass = 'h-[18px] w-[18px]';

  return (
    <div className="flex min-h-screen">
      <aside className="sticky top-0 flex h-screen w-60 shrink-0 flex-col bg-ink px-3 py-5 text-white">
        <div className="mb-8 flex items-center gap-2.5 px-2">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-white/10">
            <Snowflake className="h-5 w-5" aria-hidden />
          </div>
          <div className="leading-tight">
            <p className="font-extrabold">Déneige Auto</p>
            <p className="text-xs text-white/55">Administration</p>
          </div>
        </div>

        <nav className="flex flex-1 flex-col gap-1" aria-label="Navigation principale">
          <NavItem to="/" icon={<LayoutDashboard className={iconClass} />} label="Tableau de bord" />
          <NavItem to="/users" icon={<Users className={iconClass} />} label="Comptes" />
          <NavItem to="/reservations" icon={<CalendarCheck className={iconClass} />} label="Réservations" />
          <NavItem to="/disputes" icon={<Gavel className={iconClass} />} label="Litiges" count={counts.disputes} />
          <NavItem to="/verifications" icon={<ShieldCheck className={iconClass} />} label="Vérifications" count={counts.verifications} />
          <NavItem to="/support" icon={<LifeBuoy className={iconClass} />} label="Support" count={counts.support} />

          <p className="mb-1 mt-5 px-3 text-xs font-bold text-white/40">Opérations</p>
          <NavItem to="/workers" icon={<HardHat className={iconClass} />} label="Déneigeurs" />
          <NavItem to="/finance" icon={<Wallet className={iconClass} />} label="Finances" />
          <NavItem to="/stripe" icon={<CreditCard className={iconClass} />} label="Comptes Stripe" />
          <NavItem to="/notifications" icon={<BellRing className={iconClass} />} label="Notifications" />
        </nav>

        <div className="border-t border-white/10 px-2 pt-4">
          <p className="truncate font-bold">{user?.name}</p>
          <p className="truncate text-xs text-white/55">{user?.email}</p>
          <button
            onClick={() => logout()}
            className="mt-3 flex items-center gap-2 text-sm font-semibold text-white/65 hover:text-white"
          >
            <LogOut className="h-4 w-4" aria-hidden />
            Se déconnecter
          </button>
        </div>
      </aside>

      <main className="min-w-0 flex-1 px-8 py-7">
        <div className="mx-auto max-w-6xl">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
