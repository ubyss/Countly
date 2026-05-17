"use client";

import {
  Calendar,
  CalendarDays,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Clock3,
  Globe2,
  ImageUp,
  Plus,
  Trash2
} from "lucide-react";
import { ChangeEvent, ClipboardEvent, DragEvent, FormEvent, useEffect, useMemo, useRef, useState } from "react";

type CountlyCountdown = {
  id: string;
  name: string;
  targetDate: string;
  description: string;
  image: string;
};

type CountlyFormState = {
  name: string;
  targetDate: string;
  description: string;
  image: string;
};

type RemainingTime = {
  months: number;
  days: number;
  hours: number;
  minutes: number;
  expired: boolean;
};

const storageKey = "countly.countdowns.v3";

const initialFormState: CountlyFormState = {
  name: "",
  targetDate: "",
  description: "",
  image: ""
};

function formatDateLabel(value: string) {
  return new Intl.DateTimeFormat("pt-BR", {
    month: "long",
    day: "numeric",
    year: "numeric",
    timeZone: "UTC"
  }).format(new Date(`${value}T00:00:00Z`));
}

function formatCalendarMonth(date: Date) {
  return new Intl.DateTimeFormat("pt-BR", {
    month: "long",
    year: "numeric"
  }).format(date);
}

function toDateInputValue(date: Date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function calculateRemainingTime(targetDate: string): RemainingTime {
  const now = new Date();
  const target = new Date(`${targetDate}T23:59:59`);
  const distance = target.getTime() - now.getTime();

  if (distance <= 0) {
    return { months: 0, days: 0, hours: 0, minutes: 0, expired: true };
  }

  const minute = 1000 * 60;
  const hour = minute * 60;
  const day = hour * 24;
  const month = day * 30;

  return {
    months: Math.floor(distance / month),
    days: Math.floor((distance % month) / day),
    hours: Math.floor((distance % day) / hour),
    minutes: Math.floor((distance % hour) / minute),
    expired: false
  };
}

function padMetric(value: number) {
  return String(value).padStart(2, "0");
}

function getStoredCountdowns() {
  if (typeof window === "undefined") {
    return [];
  }

  const saved = window.localStorage.getItem(storageKey);
  if (!saved) {
    return [];
  }

  try {
    const parsed = JSON.parse(saved) as CountlyCountdown[];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export default function CountlyApp() {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const datePickerRef = useRef<HTMLDivElement>(null);
  const [countdowns, setCountdowns] = useState<CountlyCountdown[]>([]);
  const [countdownForm, setCountdownForm] = useState<CountlyFormState>(initialFormState);
  const [sortMode, setSortMode] = useState<"soonest" | "latest">("soonest");
  const [activeView, setActiveView] = useState<"countdowns" | "calendar">("countdowns");
  const [currentTime, setCurrentTime] = useState(new Date());
  const [imageMessage, setImageMessage] = useState("Clique, arraste ou cole uma imagem");
  const [storageLoaded, setStorageLoaded] = useState(false);
  const [datePickerOpen, setDatePickerOpen] = useState(false);
  const [visibleMonth, setVisibleMonth] = useState(() => new Date(new Date().getFullYear(), new Date().getMonth(), 1));

  useEffect(() => {
    setCountdowns(getStoredCountdowns());
    setStorageLoaded(true);
  }, []);

  useEffect(() => {
    if (storageLoaded) {
      window.localStorage.setItem(storageKey, JSON.stringify(countdowns));
    }
  }, [countdowns, storageLoaded]);

  useEffect(() => {
    const timer = window.setInterval(() => setCurrentTime(new Date()), 60_000);
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    function closeDatePicker(event: MouseEvent) {
      if (datePickerRef.current && !datePickerRef.current.contains(event.target as Node)) {
        setDatePickerOpen(false);
      }
    }

    document.addEventListener("mousedown", closeDatePicker);
    return () => document.removeEventListener("mousedown", closeDatePicker);
  }, []);

  const visibleCountdowns = useMemo(() => {
    return [...countdowns]
      .sort((first, second) => {
        const firstTime = new Date(first.targetDate).getTime();
        const secondTime = new Date(second.targetDate).getTime();
        return sortMode === "soonest" ? firstTime - secondTime : secondTime - firstTime;
      });
  }, [countdowns, sortMode]);

  function updateFormField<Key extends keyof CountlyFormState>(key: Key, value: CountlyFormState[Key]) {
    setCountdownForm((current) => ({ ...current, [key]: value }));
  }

  function readImageFile(file: File | undefined) {
    if (!file) {
      return;
    }

    if (!file.type.startsWith("image/")) {
      setImageMessage("Arquivo inválido. Use uma imagem.");
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      updateFormField("image", String(reader.result));
      setImageMessage("Imagem adicionada");
    };
    reader.readAsDataURL(file);
  }

  function handleImageUpload(event: ChangeEvent<HTMLInputElement>) {
    readImageFile(event.target.files?.[0]);
  }

  function handleImageDrop(event: DragEvent<HTMLDivElement>) {
    event.preventDefault();
    readImageFile(event.dataTransfer.files?.[0]);
  }

  function handleImagePaste(event: ClipboardEvent<HTMLDivElement>) {
    const pastedImage = Array.from(event.clipboardData.items)
      .find((item) => item.type.startsWith("image/"))
      ?.getAsFile();
    readImageFile(pastedImage ?? undefined);
  }

  function handleCreateCountdown(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!countdownForm.name.trim() || !countdownForm.targetDate) {
      return;
    }

    const newCountdown: CountlyCountdown = {
      id: crypto.randomUUID(),
      name: countdownForm.name.trim(),
      targetDate: countdownForm.targetDate,
      description: countdownForm.description.trim(),
      image: countdownForm.image
    };

    setCountdowns((current) => [newCountdown, ...current]);
    setCountdownForm(initialFormState);
    setImageMessage("Clique, arraste ou cole uma imagem");
  }

  function removeCountdown(id: string) {
    setCountdowns((current) => current.filter((countdown) => countdown.id !== id));
  }

  function selectCalendarDate(date: Date) {
    updateFormField("targetDate", toDateInputValue(date));
    setVisibleMonth(new Date(date.getFullYear(), date.getMonth(), 1));
    setDatePickerOpen(false);
  }

  const calendarDays = useMemo(() => {
    const firstDay = new Date(visibleMonth.getFullYear(), visibleMonth.getMonth(), 1);
    const daysInMonth = new Date(visibleMonth.getFullYear(), visibleMonth.getMonth() + 1, 0).getDate();
    const emptyCells = firstDay.getDay();
    return [
      ...Array.from({ length: emptyCells }, () => null),
      ...Array.from({ length: daysInMonth }, (_, index) => new Date(visibleMonth.getFullYear(), visibleMonth.getMonth(), index + 1))
    ];
  }, [visibleMonth]);

  return (
    <main className="countly-application-shell">
      <header className="countly-navigation-bar">
        <div className="countly-brand-lockup">
          <span className="countly-brand-mark" aria-hidden="true">
            <Clock3 size={19} />
          </span>
          <span className="countly-brand-name">Countly</span>
        </div>

        <nav className="countly-primary-tabs" aria-label="Principal">
          <button
            className={`countly-primary-tab ${activeView === "countdowns" ? "countly-primary-tab--active" : ""}`}
            type="button"
            onClick={() => setActiveView("countdowns")}
          >
            <CalendarDays size={17} />
            Contagens
          </button>
          <button
            className={`countly-primary-tab ${activeView === "calendar" ? "countly-primary-tab--active" : ""}`}
            type="button"
            onClick={() => setActiveView("calendar")}
          >
            <Calendar size={17} />
            Calendário
          </button>
        </nav>

        <div className="countly-header-actions">
          <a className="countly-create-shortcut" href="#new-countdown">
            <Plus size={20} />
            Nova contagem
          </a>
        </div>
      </header>

      <section className="countly-workspace">
        <form className="countly-creation-panel" id="new-countdown" onSubmit={handleCreateCountdown}>
          <div className="countly-creation-heading">
            <h1>Adicionar nova contagem</h1>
            <p>Crie e acompanhe seus momentos importantes.</p>
          </div>

          <div className="countly-creation-fields">
            <div
              className={`countly-image-uploader ${countdownForm.image ? "countly-image-uploader--filled" : ""}`}
              style={countdownForm.image ? { backgroundImage: `url(${countdownForm.image})` } : undefined}
              onClick={() => fileInputRef.current?.click()}
              onDragOver={(event) => event.preventDefault()}
              onDrop={handleImageDrop}
              onPaste={handleImagePaste}
              role="button"
              tabIndex={0}
              aria-label="Adicionar imagem"
            >
              {countdownForm.image ? null : (
                <>
                  <ImageUp size={38} />
                  <strong>Adicionar imagem</strong>
                  <span>JPG, PNG ou WebP</span>
                  <small>Máximo 5MB</small>
                  <em>{imageMessage}</em>
                </>
              )}
              <input ref={fileInputRef} accept="image/jpeg,image/png,image/webp" onChange={handleImageUpload} type="file" />
            </div>

            <div className="countly-form-inputs">
            <label className="countly-field-group countly-field-group--name">
              <span>Nome</span>
              <input
                value={countdownForm.name}
                onChange={(event) => updateFormField("name", event.target.value)}
                placeholder="ex.: Meu aniversário"
                required
              />
            </label>

            <label className="countly-field-group countly-field-group--date">
              <span>Data alvo</span>
              <div className="countly-date-picker-shell" ref={datePickerRef}>
                <button className="countly-date-input-wrapper" type="button" onClick={() => setDatePickerOpen((open) => !open)}>
                  <Calendar size={18} />
                  <span className={countdownForm.targetDate ? "countly-date-display" : "countly-date-display countly-date-display--empty"}>
                    {countdownForm.targetDate ? formatDateLabel(countdownForm.targetDate) : "Selecionar data"}
                  </span>
                  <ChevronDown size={18} />
                </button>

                {datePickerOpen ? (
                  <div className="countly-calendar-popover" role="dialog" aria-label="Selecionar data">
                    <div className="countly-calendar-popover-header">
                      <button
                        type="button"
                        aria-label="Mes anterior"
                        onClick={() => setVisibleMonth((month) => new Date(month.getFullYear(), month.getMonth() - 1, 1))}
                      >
                        <ChevronLeft size={17} />
                      </button>
                      <strong>{formatCalendarMonth(visibleMonth)}</strong>
                      <button
                        type="button"
                        aria-label="Proximo mes"
                        onClick={() => setVisibleMonth((month) => new Date(month.getFullYear(), month.getMonth() + 1, 1))}
                      >
                        <ChevronRight size={17} />
                      </button>
                    </div>

                    <div className="countly-calendar-weekdays">
                      {["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sab"].map((weekday) => (
                        <span key={weekday}>{weekday}</span>
                      ))}
                    </div>

                    <div className="countly-calendar-days">
                      {calendarDays.map((date, index) =>
                        date ? (
                          <button
                            className={countdownForm.targetDate === toDateInputValue(date) ? "countly-calendar-day countly-calendar-day--selected" : "countly-calendar-day"}
                            key={toDateInputValue(date)}
                            type="button"
                            onClick={() => selectCalendarDate(date)}
                          >
                            {date.getDate()}
                          </button>
                        ) : (
                          <span className="countly-calendar-day-placeholder" key={`empty-${index}`} />
                        )
                      )}
                    </div>
                  </div>
                ) : null}
              </div>
            </label>

            <label className="countly-field-group countly-field-group--description">
              <span>Descrição (opcional)</span>
              <textarea
                value={countdownForm.description}
                onChange={(event) => updateFormField("description", event.target.value)}
                placeholder="Adicione uma observação sobre esta contagem..."
              />
            </label>
            </div>

            <button className="countly-submit-button" type="submit">
              <CalendarDays size={19} />
              Adicionar contagem
            </button>
          </div>
        </form>

        <section className="countly-list-section" aria-labelledby="countly-list-title">
          <div className="countly-list-toolbar">
            <h2 id="countly-list-title">
              {activeView === "countdowns" ? "Suas contagens" : "Calendário"} <span>{visibleCountdowns.length}</span>
            </h2>

            <label className="countly-sort-control">
              <span>Ordenar por:</span>
              <select value={sortMode} onChange={(event) => setSortMode(event.target.value as "soonest" | "latest")}>
                <option value="soonest">Mais próxima</option>
                <option value="latest">Mais distante</option>
              </select>
              <ChevronDown size={17} />
            </label>
          </div>

          <div className={activeView === "countdowns" ? "countly-countdown-stack" : "countly-calendar-stack"}>
            {visibleCountdowns.map((countdown) => {
              const remainingTime = calculateRemainingTime(countdown.targetDate);
              return activeView === "countdowns" ? (
                <article className="countly-countdown-card" key={countdown.id}>
                  <div
                    className={`countly-countdown-image ${countdown.image ? "" : "countly-countdown-image--empty"}`}
                    aria-hidden="true"
                    style={countdown.image ? { backgroundImage: `url(${countdown.image})` } : undefined}
                  >
                    {countdown.image ? null : <CalendarDays size={28} />}
                  </div>

                  <div className="countly-countdown-details">
                    <h3>{countdown.name}</h3>
                    <div className="countly-countdown-meta">
                      <Calendar size={18} />
                      <time dateTime={countdown.targetDate}>{formatDateLabel(countdown.targetDate)}</time>
                    </div>
                  </div>

                  <div className="countly-time-grid" aria-label={`Tempo restante para ${countdown.name}`}>
                    <CountdownMetric label="Meses" value={remainingTime.months} />
                    <span className="countly-time-divider">:</span>
                    <CountdownMetric label="Dias" value={remainingTime.days} />
                    <span className="countly-time-divider">:</span>
                    <CountdownMetric label="Horas" value={remainingTime.hours} />
                    <span className="countly-time-divider">:</span>
                    <CountdownMetric label="Minutos" value={remainingTime.minutes} />
                  </div>

                  <button
                    className="countly-row-action"
                    onClick={() => removeCountdown(countdown.id)}
                    aria-label={`Remover ${countdown.name}`}
                    title={`Remover ${countdown.name}`}
                    type="button"
                  >
                    <Trash2 size={19} />
                  </button>
                </article>
              ) : (
                <article className="countly-calendar-item" key={countdown.id}>
                  <div className="countly-calendar-date">
                    <strong>{new Date(`${countdown.targetDate}T00:00:00Z`).getUTCDate().toString().padStart(2, "0")}</strong>
                    <span>
                      {new Intl.DateTimeFormat("pt-BR", { month: "short", timeZone: "UTC" }).format(
                        new Date(`${countdown.targetDate}T00:00:00Z`)
                      )}
                    </span>
                  </div>
                  <div className="countly-calendar-content">
                    <h3>{countdown.name}</h3>
                    <p>{countdown.description || "Sem descrição"}</p>
                  </div>
                  <CountdownMetric label="Dias" value={remainingTime.months * 30 + remainingTime.days} />
                </article>
              );
            })}
          </div>

          {visibleCountdowns.length === 0 ? (
            <div className="countly-empty-state">
              <CalendarDays size={28} />
              <p>Nenhuma contagem criada.</p>
            </div>
          ) : null}
        </section>

        <footer className="countly-timezone-note">
          <Globe2 size={17} />
          <span>Todos os horários são exibidos no seu fuso local</span>
        </footer>
      </section>
    </main>
  );
}

function CountdownMetric({ label, value }: { label: string; value: number }) {
  return (
    <div className="countly-time-metric">
      <strong>{padMetric(value)}</strong>
      <span>{label}</span>
    </div>
  );
}
