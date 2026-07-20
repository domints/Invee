export interface ShortLinkConfig {
    shortHost: string;
    canonicalBaseUrl: string;
}

let cached: Promise<ShortLinkConfig | null> | null = null;

export const getShortLinkConfig = (): Promise<ShortLinkConfig | null> => {
    if (!cached) {
        const base = (import.meta.env.VITE_API_BASE_URL ?? '/').replace(/\/+$/, '');
        cached = fetch(`${base}/api/health`, { credentials: 'include' })
            .then(r => (r.ok ? r.json() : null))
            .then(d => (d ? { shortHost: d.shortHost ?? '', canonicalBaseUrl: d.canonicalBaseUrl ?? '' } : null))
            .catch(() => null);
    }
    return cached;
};

export const isMobileDevice = (): boolean => {
    const uaData = (navigator as unknown as { userAgentData?: { mobile?: boolean } }).userAgentData;
    if (uaData && typeof uaData.mobile === 'boolean') return uaData.mobile;
    return /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
};

export const buildAppLink = (
    config: ShortLinkConfig,
    kind: 'item' | 'storage',
    slug: string,
): string => {
    const server = encodeURIComponent(config.canonicalBaseUrl || window.location.origin);
    return `invee://${kind}?slug=${encodeURIComponent(slug)}&server=${server}`;
};
