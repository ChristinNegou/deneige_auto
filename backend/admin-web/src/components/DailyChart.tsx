import { useState } from 'react';
import { formatMoney, formatShortDay } from '../lib/format';

interface Point {
  _id: string;
  count: number;
  revenue: number;
}

/** Graduations "rondes" de l'axe vertical (0, 2, 4…). */
function niceTicks(max: number): number[] {
  if (max <= 0) return [0, 1];
  const step = Math.pow(10, Math.floor(Math.log10(max)));
  const nice = [1, 2, 5, 10].map((m) => m * step).find((s) => max / s <= 5) ?? step * 10;
  const top = Math.ceil(max / nice) * nice;
  return Array.from({ length: top / nice + 1 }, (_, i) => i * nice);
}

/**
 * Reservations par jour : une seule serie (pas de legende, le titre la nomme),
 * colonnes de 24 px max a bout arrondi, survol avec infobulle, table accessible.
 */
export function DailyChart({ data }: { data: Point[] }) {
  const [hover, setHover] = useState<number | null>(null);
  const ticks = niceTicks(Math.max(...data.map((d) => d.count), 0));
  const top = ticks[ticks.length - 1] || 1;
  const height = 180;
  const labelEvery = Math.ceil(data.length / 8);

  return (
    <figure>
      <div className="relative flex gap-3" style={{ height }}>
        {/* Axe vertical */}
        <div className="tabular relative w-6 text-right text-xs text-slate-3" aria-hidden>
          {ticks.map((t) => (
            <span key={t} className="absolute right-0 -translate-y-1/2" style={{ bottom: `${(t / top) * 100}%` }}>
              {t}
            </span>
          ))}
        </div>

        <div className="relative flex-1">
          {/* Grille horizontale discrete */}
          {ticks.map((t) => (
            <div key={t} className="absolute inset-x-0 border-t border-line/70" style={{ bottom: `${(t / top) * 100}%` }} aria-hidden />
          ))}

          <div className="absolute inset-0 flex items-end gap-0.5">
            {data.map((d, i) => (
              <div
                key={d._id}
                className="relative flex h-full flex-1 items-end justify-center"
                onMouseEnter={() => setHover(i)}
                onMouseLeave={() => setHover(null)}
              >
                <div
                  className="w-full max-w-[24px] rounded-t transition-opacity"
                  style={{
                    height: `${(d.count / top) * 100}%`,
                    minHeight: d.count > 0 ? 2 : 0,
                    background: '#2F6FB0',
                    opacity: hover === null || hover === i ? 1 : 0.45,
                  }}
                />
                {hover === i && (
                  <div className="pointer-events-none absolute bottom-full z-10 mb-2 whitespace-nowrap rounded-lg bg-ink px-3 py-2 text-xs text-white shadow-pop">
                    <p className="font-bold">{formatShortDay(d._id)}</p>
                    <p className="tabular">{d.count} réservation{d.count > 1 ? 's' : ''}</p>
                    <p className="tabular text-white/70">{formatMoney(d.revenue)}</p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Axe horizontal : une date sur N pour eviter les chevauchements */}
      <div className="ml-9 mt-2 flex gap-0.5 text-xs text-slate-3" aria-hidden>
        {data.map((d, i) => (
          <span key={d._id} className="flex-1 text-center">
            {i % labelEvery === 0 ? formatShortDay(d._id) : ''}
          </span>
        ))}
      </div>

      <table className="sr-only">
        <caption>Réservations par jour</caption>
        <thead>
          <tr>
            <th>Jour</th>
            <th>Réservations</th>
            <th>Montant</th>
          </tr>
        </thead>
        <tbody>
          {data.map((d) => (
            <tr key={d._id}>
              <td>{formatShortDay(d._id)}</td>
              <td>{d.count}</td>
              <td>{formatMoney(d.revenue)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
