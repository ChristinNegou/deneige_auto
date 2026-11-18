import { useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';

/**
 * Filtres de liste gardes dans l'URL : un lien partage ou le bouton Retour
 * retrouvent exactement la meme vue. Changer un filtre ramene a la page 1.
 */
export function useListParams<K extends string>(keys: readonly K[]) {
  const [params, setParams] = useSearchParams();

  const values = Object.fromEntries(keys.map((k) => [k, params.get(k) ?? ''])) as Record<K, string>;
  const page = Math.max(1, Number(params.get('page')) || 1);

  const set = useCallback(
    (key: K | 'page', value: string | number) => {
      setParams(
        (prev) => {
          const next = new URLSearchParams(prev);
          if (value === '' || value === undefined) next.delete(key);
          else next.set(key, String(value));
          if (key !== 'page') next.delete('page');
          return next;
        },
        { replace: true },
      );
    },
    [setParams],
  );

  return { values, page, set };
}
