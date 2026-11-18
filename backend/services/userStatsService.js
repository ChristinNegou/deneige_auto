/**
 * Statistiques des comptes pour le back-office : inscriptions, et activite
 * des clients et deneigeurs par ville.
 *
 * Les comptes n'ont pas de region : la ville vient de l'adresse des
 * reservations ("3746 Boulevard Jean-XXIII, Trois-Rivieres, Quebec G8Z 3X4").
 */

const User = require('../models/User');
const Reservation = require('../models/Reservation');

const TIMEZONE = 'America/Toronto';
const UNKNOWN_CITY = 'Ville inconnue';

const PERIOD_DAYS = { month: 30, quarter: 90, year: 365 };

/** Cle de regroupement : sans accents ni casse ("Trois-Rivières" = "trois-rivieres"). */
const cityKey = (city) => city.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

/**
 * Ville d'une adresse "numero rue, ville, province ...". Retourne null si
 * l'adresse n'a pas de partie ville.
 */
function cityFromAddress(address) {
    if (!address || typeof address !== 'string') return null;
    const parts = address.split(',').map((p) => p.trim()).filter(Boolean);
    if (parts.length < 2) return null;
    // "Montréal QC H2X 1Y4" -> "Montréal"
    const city = parts[1]
        .replace(/\s+[A-Z]\d[A-Z]\s?\d[A-Z]\d$/i, '')
        .replace(/\s+(QC|Qc|Québec|Quebec)$/, '')
        .trim();
    if (!city || /^\d/.test(city) || /^(canada|qc|québec|quebec)$/i.test(city)) return null;
    return city;
}

const fullName = (u) => (u ? `${u.firstName || ''} ${u.lastName || ''}`.trim() : '');

/** Les 12 derniers mois "AAAA-MM", du plus ancien au mois courant. */
function lastTwelveMonths(now = new Date()) {
    return Array.from({ length: 12 }, (_, i) => {
        const d = new Date(now.getFullYear(), now.getMonth() - 11 + i, 1);
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    });
}

/**
 * @param {Object} options
 * @param {'month'|'quarter'|'year'|'all'} [options.period='year'] - fenetre de l'activite par ville
 * @param {string} [options.city] - limite les classements a une ville
 */
async function getUserStats({ period = 'year', city } = {}) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const months = lastTwelveMonths(now);
    const twelveMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 11, 1);

    const roles = { $in: ['client', 'snowWorker'] };
    const [byRole, newThisMonth, newLastMonth, signups] = await Promise.all([
        User.aggregate([{ $match: { role: roles } }, { $group: { _id: '$role', count: { $sum: 1 } } }]),
        User.aggregate([
            { $match: { role: roles, createdAt: { $gte: startOfMonth } } },
            { $group: { _id: '$role', count: { $sum: 1 } } },
        ]),
        User.aggregate([
            { $match: { role: roles, createdAt: { $gte: startOfLastMonth, $lt: startOfMonth } } },
            { $group: { _id: '$role', count: { $sum: 1 } } },
        ]),
        User.aggregate([
            { $match: { role: roles, createdAt: { $gte: twelveMonthsAgo } } },
            {
                $group: {
                    _id: {
                        month: { $dateToString: { format: '%Y-%m', date: '$createdAt', timezone: TIMEZONE } },
                        role: '$role',
                    },
                    count: { $sum: 1 },
                },
            },
        ]),
    ]);

    const countFor = (rows, role) => rows.find((r) => r._id === role)?.count || 0;
    const roleCounts = (rows) => ({ clients: countFor(rows, 'client'), workers: countFor(rows, 'snowWorker') });

    const signupsByMonth = months.map((month) => ({
        month,
        clients: signups.find((s) => s._id.month === month && s._id.role === 'client')?.count || 0,
        workers: signups.find((s) => s._id.month === month && s._id.role === 'snowWorker')?.count || 0,
    }));

    // --- Activite par ville sur la periode ---
    const match = {};
    if (PERIOD_DAYS[period]) {
        match.createdAt = { $gte: new Date(now.getTime() - PERIOD_DAYS[period] * 24 * 3600 * 1000) };
    }
    const reservations = await Reservation.find(match)
        .select('userId workerId status totalPrice tipAmount payout.workerAmount location.address')
        .lean();

    const cities = new Map(); // cle -> { city, clients:Set, workers:Set, reservations, completed, revenue }
    const clients = new Map(); // id -> { reservations, completed, spent, cities: Map }
    const workers = new Map(); // id -> { jobs, earnings, cities: Map }
    const wantedKey = city ? cityKey(city) : null;

    for (const r of reservations) {
        const name = cityFromAddress(r.location?.address) || UNKNOWN_CITY;
        const key = cityKey(name);
        const completed = r.status === 'completed';
        const cancelled = r.status === 'cancelled';

        if (!cities.has(key)) {
            cities.set(key, { city: name, clients: new Set(), workers: new Set(), reservations: 0, completed: 0, revenue: 0 });
        }
        const c = cities.get(key);
        c.reservations += 1;
        if (r.userId) c.clients.add(String(r.userId));
        if (completed) {
            c.completed += 1;
            c.revenue += r.totalPrice || 0;
            if (r.workerId) c.workers.add(String(r.workerId));
        }

        if (wantedKey && key !== wantedKey) continue;

        if (r.userId && !cancelled) {
            const id = String(r.userId);
            const s = clients.get(id) || { reservations: 0, completed: 0, spent: 0, cities: new Map() };
            s.reservations += 1;
            if (completed) {
                s.completed += 1;
                s.spent += r.totalPrice || 0;
            }
            s.cities.set(name, (s.cities.get(name) || 0) + 1);
            clients.set(id, s);
        }
        if (r.workerId && completed) {
            const id = String(r.workerId);
            const s = workers.get(id) || { jobs: 0, earnings: 0, cities: new Map() };
            s.jobs += 1;
            s.earnings += (r.payout?.workerAmount || 0) + (r.tipAmount || 0);
            s.cities.set(name, (s.cities.get(name) || 0) + 1);
            workers.set(id, s);
        }
    }

    const mainCity = (map) => [...map.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] || UNKNOWN_CITY;

    const topClientIds = [...clients.entries()]
        .sort((a, b) => b[1].reservations - a[1].reservations || b[1].spent - a[1].spent)
        .slice(0, 10);
    const topWorkerIds = [...workers.entries()]
        .sort((a, b) => b[1].jobs - a[1].jobs || b[1].earnings - a[1].earnings)
        .slice(0, 10);

    const people = await User.find({ _id: { $in: [...topClientIds, ...topWorkerIds].map(([id]) => id) } })
        .select('firstName lastName workerProfile.averageRating')
        .lean();
    const byId = new Map(people.map((p) => [String(p._id), p]));

    const clientsWithReservation = await Reservation.distinct('userId');
    const totals = roleCounts(byRole);

    return {
        totals: { users: totals.clients + totals.workers, ...totals },
        newThisMonth: roleCounts(newThisMonth),
        newLastMonth: roleCounts(newLastMonth),
        clientsWithoutReservation: Math.max(
            0,
            totals.clients - (await User.countDocuments({ role: 'client', _id: { $in: clientsWithReservation } })),
        ),
        signupsByMonth,
        period,
        city: city || null,
        cities: [...cities.values()]
            .map((c) => ({
                city: c.city,
                clients: c.clients.size,
                workers: c.workers.size,
                reservations: c.reservations,
                completed: c.completed,
                revenue: Math.round(c.revenue * 100) / 100,
            }))
            .sort((a, b) => b.reservations - a.reservations),
        topClients: topClientIds.map(([id, s]) => ({
            id,
            name: fullName(byId.get(id)) || 'Compte supprimé',
            city: mainCity(s.cities),
            reservations: s.reservations,
            completed: s.completed,
            spent: Math.round(s.spent * 100) / 100,
        })),
        topWorkers: topWorkerIds.map(([id, s]) => ({
            id,
            name: fullName(byId.get(id)) || 'Compte supprimé',
            city: mainCity(s.cities),
            jobs: s.jobs,
            earnings: Math.round(s.earnings * 100) / 100,
            rating: byId.get(id)?.workerProfile?.averageRating || 0,
        })),
    };
}

module.exports = { getUserStats, cityFromAddress, UNKNOWN_CITY };
