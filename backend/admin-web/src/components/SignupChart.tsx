import { useState } from 'react';

interface Month {
  month: string; // AAAA-MM
  clients: number;
  workers: number;
}

/** Memes couleurs que les roles dans l'application (verifiees daltonisme). */
export const ROLE_COLORS = { clients: '#2F6FB0', workers: '#C9520F' } as const;

const monthFmt = new Intl.DateTimeFormat('fr-CA', { month: 'short' });
const monthLongFmt = new Intl.DateTimeFormat('fr-CA', { month: 'long', year: 'numeric' });
const toDate = (month: string) => {
  const [y, m] = month.split('-').map(Number);
  return new Date(y, m - 1, 1);
};

function niceTicks(max: number): number[] {
  if (max <= 0) return [0, 1];
  const step = Math.pow(10, Math.floor(Math.log10(max)));
  const nice = [1, 2, 5, 10].map((m) => m * step).find((s) => max / s <= 5) ?? step * 10;
  const top = Math.ceil(max / nice) * nice;
  return Array.from({ length: top / nice + 1 }, (_, i) => i * nice);
}

/**
 * Inscriptions par mois, clients et deneigeurs empiles. Legende au-dessus,
 * infobulle au survol, ecart de 2 px entre les segments, table accessible.
 */
export function SignupChart({ data }: { data: Month[] }) {
  const [hover, setHover] = useState<number | null>(null);
  const ticks = niceTicks(Math.max(...data.map((d) => d.clients + d.workers), 0));
  const top = ticks[ticks.length - 1] || 1;
  const height = 200;

  return (
    <figure>
      <div className="mb-4 flex gap-5 text-sm text-slate-2">
        {(['clients', 'workers'] as const).map((key) => (
          <span key={key} className="flex items-center gap-2">
            <span className="h-2.5 w-2.5 rounded-sm" style={{ background: ROLE_COLORS[key] }} aria-hidden />
            {key === 'clients' ? 'Clients' : 'Déneigeurs'}
          </span>
        ))}
      </div>

      <div className="relative flex gap-3" style={{ height }}>
        <div className="tabular relative w-6 text-right text-xs text-slate-3" aria-hidden>
          {ticks.map((t) => (
            <span key={t} className="absolute right-0 -translate-y-1/2" style={{ bottom: `${(t / top) * 100}%` }}>
              {t}
            </span>
          ))}
        </div>

        <div className="relative flex-1">
          {ticks.map((t) => (
            <div key={t} className="absolute inset-x-0 border-t border-line/70" style={{ bottom: `${(t / top) * 100}%` }} aria-hidden />
          ))}

          <div className="absolute inset-0 flex items-end gap-1">
            {data.map((d, i) => {
              const total = d.clients + d.workers;
              return (
                <div
                  key={d.month}
                  className="relative flex h-full flex-1 flex-col items-center justify-end"
                  onMouseEnter={() => setHover(i)}
                  onMouseLeave={() => setHover(null)}
                >
                  <div
                    className="flex w-full max-w-[28px] flex-col justify-end gap-[2px] transition-opacity"
                    style={{ height: `${(total / top) * 100}%`, opacity: hover === null || hover === i ? 1 : 0.45 }}
                  >
                    {d.workers > 0 && (
                      <div
                        className="rounded-t"
                        style={{ flexGrow: d.workers, minHeight: 2, background: ROLE_COLORS.workers }}
                      />
                    )}
                    {d.clients > 0 && (
                      <div
                        className={d.workers > 0 ? '' : 'rounded-t'}
                        style={{ flexGrow: d.clients, minHeight: 2, background: ROLE_COLORS.clients }}
                      />
                    )}
                  </div>
                  {hover === i && (
                    <div className="pointer-events-none absolute bottom-full z-10 mb-2 whitespace-nowrap rounded-lg bg-ink px-3 py-2 text-xs text-white shadow-pop">
                      <p className="font-bold first-letter:uppercase">{monthLongFmt.format(toDate(d.month))}</p>
                      <p className="tabular">{d.clients} client{d.clients > 1 ? 's' : ''}</p>
                      <p className="tabular">{d.workers} déneigeur{d.workers > 1 ? 's' : ''}</p>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>

      <div className="ml-9 mt-2 flex gap-1 text-xs text-slate-3" aria-hidden>
        {data.map((d) => (
          <span key={d.month} className="flex-1 text-center">
            {monthFmt.format(toDate(d.month)).replace('.', '')}
          </span>
        ))}
      </div>

      <table className="sr-only">
        <caption>Inscriptions par mois</caption>
        <thead>
          <tr>
            <th>Mois</th>
            <th>Clients</th>
            <th>Déneigeurs</th>
          </tr>
        </thead>
        <tbody>
          {data.map((d) => (
            <tr key={d.month}>
              <td>{monthLongFmt.format(toDate(d.month))}</td>
              <td>{d.clients}</td>
              <td>{d.workers}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
