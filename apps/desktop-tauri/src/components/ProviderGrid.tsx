import type { CSSProperties } from "react";
import type { ProviderUsageSnapshot } from "../types/bridge";
import { ProviderIcon } from "./providers/ProviderIcon";
import { getProviderIcon } from "./providers/providerIcons";

export default function ProviderGrid({
  providers,
  selectedProviderId,
  showAsUsed,
  onSelect,
}: {
  providers: ProviderUsageSnapshot[];
  selectedProviderId: string | null;
  showAsUsed: boolean;
  onSelect: (providerId: string | null) => void;
}) {
  const gridPercent = (provider: ProviderUsageSnapshot) => {
    const pct = showAsUsed
      ? provider.primary.usedPercent
      : provider.primary.remainingPercent;
    return Math.max(0, Math.min(100, pct));
  };

  return (
    <div
      className={`provider-grid${
        providers.length + 1 <= 6 ? " provider-grid--sparse" : ""
      }`}
    >
      <button
        type="button"
        className={`provider-grid__item${selectedProviderId === null ? " provider-grid__item--active" : ""}`}
        onClick={() => onSelect(null)}
        title="Overview"
      >
        <span className="provider-grid__icon-overview">⊞</span>
        <span className="provider-grid__label">All</span>
      </button>
      {providers.map((p) => (
        <button
          key={p.providerId}
          type="button"
          className={`provider-grid__item${p.providerId === selectedProviderId ? " provider-grid__item--active" : ""}`}
          onClick={() => onSelect(p.providerId)}
          title={p.displayName}
        >
          <ProviderIcon providerId={p.providerId} size={16} />
          <span className="provider-grid__label">{p.displayName}</span>
          {!p.error && (
            <span
              className="provider-grid__weekly-track"
              style={{
                "--weekly-pct": `${gridPercent(p)}%`,
                "--weekly-color": getProviderIcon(p.providerId).brandColor,
              } as CSSProperties}
            />
          )}
        </button>
      ))}
    </div>
  );
}
