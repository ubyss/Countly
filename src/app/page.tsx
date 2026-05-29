"use client";

import {
  Calendar,
  CalendarDays,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  CircleCheck,
  Clock3,
  Globe2,
  ImageUp,
  MoreVertical,
  Moon,
  Pencil,
  Sun,
  Trash2,
  Undo2
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

function getMonthStart(referenceDate: Date) {
  return new Date(referenceDate.getFullYear(), referenceDate.getMonth(), 1);
}

function isMonthAfterReference(month: Date, referenceMonth: Date) {
  return month.getFullYear() > referenceMonth.getFullYear()
    || (month.getFullYear() === referenceMonth.getFullYear() && month.getMonth() > referenceMonth.getMonth());
}

function isMonthBeforeReference(month: Date, referenceMonth: Date) {
  return month.getFullYear() < referenceMonth.getFullYear()
    || (month.getFullYear() === referenceMonth.getFullYear() && month.getMonth() < referenceMonth.getMonth());
}

function isoDateToLocalDate(isoDate: string) {
  const isoMatch = /^(\d{4})-(\d{2})-(\d{2})/.exec(isoDate);
  if (!isoMatch) {
    return null;
  }

  return new Date(Number(isoMatch[1]), Number(isoMatch[2]) - 1, Number(isoMatch[3]));
}

function formatBrazilianDateInput(isoDate: string) {
  const isoMatch = /^(\d{4})-(\d{2})-(\d{2})/.exec(normalizeTargetDate(isoDate));
  if (!isoMatch) {
    return "";
  }

  return `${isoMatch[3]}/${isoMatch[2]}/${isoMatch[1]}`;
}

function parseBrazilianDateInput(value: string) {
  const match = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(value.trim());
  if (!match) {
    return "";
  }

  const day = Number(match[1]);
  const month = Number(match[2]);
  const year = Number(match[3]);
  const parsedDate = new Date(year, month - 1, day);

  if (
    parsedDate.getFullYear() !== year
    || parsedDate.getMonth() !== month - 1
    || parsedDate.getDate() !== day
  ) {
    return "";
  }

  return toDateInputValue(parsedDate);
}

function isDateBeforeToday(date: Date, today: Date) {
  const dateStart = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  return dateStart < todayStart;
}

function normalizeTargetDate(value: unknown) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return toDateInputValue(new Date(value));
  }

  if (typeof value !== "string") {
    return "";
  }

  const trimmed = value.trim();
  const isoMatch = /^(\d{4})-(\d{2})-(\d{2})/.exec(trimmed);
  if (isoMatch) {
    return `${isoMatch[1]}-${isoMatch[2]}-${isoMatch[3]}`;
  }

  const brazilianDate = parseBrazilianDateInput(trimmed);
  if (brazilianDate) {
    return brazilianDate;
  }

  const parsed = new Date(trimmed);
  if (Number.isNaN(parsed.getTime())) {
    return "";
  }

  return toDateInputValue(parsed);
}

function getTargetEndTimestamp(targetDate: string) {
  const isoMatch = /^(\d{4})-(\d{2})-(\d{2})/.exec(targetDate.trim());
  if (!isoMatch) {
    return null;
  }

  const year = Number(isoMatch[1]);
  const month = Number(isoMatch[2]) - 1;
  const day = Number(isoMatch[3]);
  const targetEnd = new Date(year, month, day, 23, 59, 59, 999);

  if (Number.isNaN(targetEnd.getTime())) {
    return null;
  }

  return targetEnd.getTime();
}

function calculateRemainingTime(targetDate: string, referenceDate: Date): RemainingTime {
  const normalizedDate = normalizeTargetDate(targetDate);
  const targetEnd = getTargetEndTimestamp(normalizedDate);

  if (!targetEnd) {
    return { months: 0, days: 0, hours: 0, minutes: 0, expired: true };
  }

  const distance = targetEnd - referenceDate.getTime();

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
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed.map((countdown) => ({
      ...countdown,
      targetDate: normalizeTargetDate(countdown.targetDate)
    }));
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
  const [editingCountdownId, setEditingCountdownId] = useState<string | null>(null);
  const [activeMenuId, setActiveMenuId] = useState<string | null>(null);
  const [theme, setTheme] = useState<"light" | "dark">("light");
  const [visibleMonth, setVisibleMonth] = useState(() => new Date(new Date().getFullYear(), new Date().getMonth(), 1));
  const [dateInputDraft, setDateInputDraft] = useState("");

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
    const updateNow = () => setCurrentTime(new Date());
    updateNow();
    const timer = window.setInterval(updateNow, 1000);
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

  useEffect(() => {
    setDateInputDraft(countdownForm.targetDate ? formatBrazilianDateInput(countdownForm.targetDate) : "");
  }, [countdownForm.targetDate]);

  const visibleCountdowns = useMemo(() => {
    return [...countdowns]
      .sort((first, second) => {
        const firstTime = getTargetEndTimestamp(normalizeTargetDate(first.targetDate)) ?? 0;
        const secondTime = getTargetEndTimestamp(normalizeTargetDate(second.targetDate)) ?? 0;
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

    const savedCountdown: CountlyCountdown = {
      id: editingCountdownId ?? crypto.randomUUID(),
      name: countdownForm.name.trim(),
      targetDate: normalizeTargetDate(countdownForm.targetDate),
      description: countdownForm.description.trim(),
      image: countdownForm.image
    };

    setCountdowns((current) => {
      if (editingCountdownId) {
        return current.map((countdown) => (countdown.id === editingCountdownId ? savedCountdown : countdown));
      }

      return [savedCountdown, ...current];
    });
    setCountdownForm(initialFormState);
    setEditingCountdownId(null);
    setImageMessage("Clique, arraste ou cole uma imagem");
  }

  function removeCountdown(id: string) {
    setCountdowns((current) => current.filter((countdown) => countdown.id !== id));
    if (editingCountdownId === id) {
      setEditingCountdownId(null);
      setCountdownForm(initialFormState);
      setImageMessage("Clique, arraste ou cole uma imagem");
    }
    setActiveMenuId(null);
  }

  function editCountdown(countdown: CountlyCountdown) {
    setCountdownForm({
      name: countdown.name,
      targetDate: countdown.targetDate,
      description: countdown.description,
      image: countdown.image
    });
    setEditingCountdownId(countdown.id);
    setImageMessage(countdown.image ? "Imagem adicionada" : "Clique, arraste ou cole uma imagem");
    setActiveMenuId(null);
    document.getElementById("new-countdown")?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  function selectCalendarDate(date: Date) {
    if (isDateBeforeToday(date, currentTime)) {
      return;
    }

    const isoDate = toDateInputValue(date);
    updateFormField("targetDate", isoDate);
    setDateInputDraft(formatBrazilianDateInput(isoDate));
    setVisibleMonth(new Date(date.getFullYear(), date.getMonth(), 1));
    setDatePickerOpen(false);
  }

  function applyTargetDate(isoDate: string) {
    const normalizedDate = normalizeTargetDate(isoDate);
    if (!normalizedDate) {
      return false;
    }

    const localDate = isoDateToLocalDate(normalizedDate);
    if (!localDate || isDateBeforeToday(localDate, currentTime)) {
      return false;
    }

    updateFormField("targetDate", normalizedDate);
    setDateInputDraft(formatBrazilianDateInput(normalizedDate));
    setVisibleMonth(getMonthStart(localDate));
    return true;
  }

  function commitDateInput() {
    if (!dateInputDraft.trim()) {
      updateFormField("targetDate", "");
      return;
    }

    if (!applyTargetDate(dateInputDraft)) {
      setDateInputDraft(countdownForm.targetDate ? formatBrazilianDateInput(countdownForm.targetDate) : "");
    }
  }

  function goToPreviousMonth() {
    setVisibleMonth((month) => {
      const previousMonth = new Date(month.getFullYear(), month.getMonth() - 1, 1);
      return isMonthBeforeReference(previousMonth, currentMonthStart) ? currentMonthStart : previousMonth;
    });
  }

  function goToNextMonth() {
    setVisibleMonth((month) => new Date(month.getFullYear(), month.getMonth() + 1, 1));
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

  const currentMonthStart = useMemo(() => getMonthStart(currentTime), [currentTime]);
  const isViewingFutureMonth = isMonthAfterReference(visibleMonth, currentMonthStart);
  const canGoToPreviousMonth = isViewingFutureMonth;

  function openDatePicker() {
    setVisibleMonth((month) => (isMonthBeforeReference(month, currentMonthStart) ? currentMonthStart : month));
    setDatePickerOpen(true);
  }

  return (
    <main className="countly-application-shell" data-theme={theme}>
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
          <button
            className="countly-theme-toggle"
            type="button"
            onClick={() => setTheme((current) => (current === "light" ? "dark" : "light"))}
            aria-label={theme === "light" ? "Ativar tema escuro" : "Ativar tema claro"}
            title={theme === "light" ? "Ativar tema escuro" : "Ativar tema claro"}
          >
            {theme === "light" ? <Moon size={19} /> : <Sun size={19} />}
          </button>
        </div>
      </header>

      <section className={`countly-workspace ${activeView === "countdowns" ? "countly-workspace--quad-grid" : ""}`}>
        <div className="countly-creation-heading" id="new-countdown">
          <h1>Adicionar nova contagem</h1>
          <p>Crie e acompanhe seus momentos importantes.</p>
        </div>

        <div className={activeView === "countdowns" ? "countly-workspace-hero-row" : "countly-creation-stack"}>
        <form className="countly-creation-panel" onSubmit={handleCreateCountdown}>
          <div className="countly-creation-fields">
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
                  <div className="countly-date-input-wrapper">
                    <button
                      className="countly-date-input-wrapper__calendar-trigger"
                      type="button"
                      aria-label="Abrir calendario"
                      onClick={() => (datePickerOpen ? setDatePickerOpen(false) : openDatePicker())}
                    >
                      <Calendar size={18} />
                    </button>
                    <input
                      className="countly-date-input-field"
                      value={dateInputDraft}
                      onChange={(event) => setDateInputDraft(event.target.value)}
                      onFocus={openDatePicker}
                      onBlur={commitDateInput}
                      onKeyDown={(event) => {
                        if (event.key === "Enter") {
                          event.preventDefault();
                          commitDateInput();
                          setDatePickerOpen(false);
                        }
                      }}
                      placeholder="dd/mm/aaaa"
                      inputMode="numeric"
                      aria-label="Data alvo"
                    />
                    <button
                      className="countly-date-input-wrapper__toggle"
                      type="button"
                      aria-label={datePickerOpen ? "Fechar calendario" : "Abrir calendario"}
                      onClick={() => (datePickerOpen ? setDatePickerOpen(false) : openDatePicker())}
                    >
                      <ChevronDown size={18} />
                    </button>
                  </div>

                  {datePickerOpen ? (
                    <div className="countly-calendar-popover" role="dialog" aria-label="Selecionar data">
                      <div className="countly-calendar-popover-header">
                        <div className="countly-calendar-popover-header__start">
                          {canGoToPreviousMonth ? (
                            <button type="button" aria-label="Mes anterior" onClick={goToPreviousMonth}>
                              <ChevronLeft size={17} />
                            </button>
                          ) : (
                            <span className="countly-calendar-nav-placeholder" aria-hidden="true" />
                          )}
                          {isViewingFutureMonth ? (
                            <button
                              className="countly-calendar-popover-header__return-month"
                              type="button"
                              aria-label="Voltar ao mes atual"
                              onClick={() => setVisibleMonth(currentMonthStart)}
                            >
                              <Undo2 size={17} />
                            </button>
                          ) : null}
                        </div>
                        <strong>{formatCalendarMonth(visibleMonth)}</strong>
                        <button type="button" aria-label="Proximo mes" onClick={goToNextMonth}>
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
                              className={[
                                "countly-calendar-day",
                                countdownForm.targetDate === toDateInputValue(date) ? "countly-calendar-day--selected" : "",
                                isDateBeforeToday(date, currentTime) ? "countly-calendar-day--disabled" : ""
                              ]
                                .filter(Boolean)
                                .join(" ")}
                              key={toDateInputValue(date)}
                              type="button"
                              disabled={isDateBeforeToday(date, currentTime)}
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
            </div>

            <article className="countly-countdown-card countly-countdown-card--preview" aria-label="Pre-visualização do card">
              <div
                className={`countly-countdown-image ${countdownForm.image ? "" : "countly-countdown-image--empty"}`}
                style={countdownForm.image ? { backgroundImage: `url(${countdownForm.image})` } : undefined}
                onDragOver={(event) => event.preventDefault()}
                onDrop={handleImageDrop}
                onPaste={handleImagePaste}
                role="button"
                tabIndex={0}
                aria-label="Adicionar imagem"
              >
                {!countdownForm.image && !countdownForm.targetDate ? (
                  <div className="countly-preview-upload-hint">
                    <ImageUp size={28} />
                    <strong>Adicionar imagem</strong>
                    <span>Clique, arraste ou cole</span>
                    <em>{imageMessage}</em>
                  </div>
                ) : null}
                <input ref={fileInputRef} accept="image/jpeg,image/png,image/webp" onChange={handleImageUpload} type="file" />

                <CountdownTimeOverlay
                  className="countly-time-grid--preview"
                  currentTime={currentTime}
                  targetDate={countdownForm.targetDate}
                  ariaLabel="Tempo restante da pre-visualização"
                />
              </div>

              <div className="countly-countdown-details countly-countdown-details--preview">
                <h3>{countdownForm.name.trim() || "Nome da contagem"}</h3>
              </div>
            </article>

            <button className="countly-submit-button" type="submit">
              <CalendarDays size={19} />
              {editingCountdownId ? "Salvar contagem" : "Adicionar contagem"}
            </button>
          </div>
        </form>

        {activeView === "countdowns" ? (
          <div className="countly-workspace-hero-aside" aria-labelledby="countly-list-title">
            <h2 className="countly-workspace-hero-aside__title" id="countly-list-title">
              Suas contagens <span>{visibleCountdowns.length}</span>
            </h2>

            {visibleCountdowns.length === 0 ? (
              <div className="countly-empty-state countly-empty-state--workspace">
                <CalendarDays size={28} />
                <p>Nenhuma contagem criada.</p>
              </div>
            ) : (
              <div className="countly-workspace-hero-aside__cards">
                {visibleCountdowns.slice(0, 2).map((countdown) => (
                  <CountdownListCard
                    key={countdown.id}
                    countdown={countdown}
                    currentTime={currentTime}
                    activeMenuId={activeMenuId}
                    onMenuToggle={(id) => setActiveMenuId((current) => (current === id ? null : id))}
                    onEdit={editCountdown}
                    onRemove={removeCountdown}
                  />
                ))}
              </div>
            )}
          </div>
        ) : null}
        </div>

        {activeView === "countdowns" ? (
          visibleCountdowns.slice(2).map((countdown) => (
            <CountdownListCard
              key={countdown.id}
              countdown={countdown}
              currentTime={currentTime}
              activeMenuId={activeMenuId}
              onMenuToggle={(id) => setActiveMenuId((current) => (current === id ? null : id))}
              onEdit={editCountdown}
              onRemove={removeCountdown}
            />
          ))
        ) : (
          <section className="countly-list-section" aria-labelledby="countly-list-title">
            <div className="countly-list-toolbar">
              <h2 id="countly-list-title">
                Calendário <span>{visibleCountdowns.length}</span>
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

            <div className="countly-calendar-stack">
              {visibleCountdowns.map((countdown) => {
                const remainingTime = calculateRemainingTime(countdown.targetDate, currentTime);
                return (
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
        )}

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

function CountdownTimeOverlay({
  ariaLabel,
  className = "",
  currentTime,
  targetDate
}: {
  ariaLabel: string;
  className?: string;
  currentTime: Date;
  targetDate: string;
}) {
  const remainingTime = targetDate
    ? calculateRemainingTime(targetDate, currentTime)
    : { months: 0, days: 0, hours: 0, minutes: 0, expired: false };

  if (targetDate && remainingTime.expired) {
    return (
      <div className={`countly-countdown-completed ${className}`.trim()} aria-label={ariaLabel}>
        <span className="countly-countdown-completed__icon" aria-hidden="true">
          <CircleCheck size={18} strokeWidth={2.4} />
        </span>
        <span className="countly-countdown-completed__copy">
          <span className="countly-countdown-completed__label">Evento concluído em</span>
          <span className="countly-countdown-completed__date">{formatBrazilianDateInput(targetDate)}</span>
        </span>
      </div>
    );
  }

  return (
    <div className={`countly-time-grid ${className}`.trim()} aria-label={ariaLabel}>
      <CountdownMetric label="Meses" value={remainingTime.months} />
      <CountdownMetric label="Dias" value={remainingTime.days} />
      <CountdownMetric label="Horas" value={remainingTime.hours} />
      <CountdownMetric label="Minutos" value={remainingTime.minutes} />
    </div>
  );
}

function CountdownListCard({
  className = "",
  countdown,
  currentTime,
  activeMenuId,
  onMenuToggle,
  onEdit,
  onRemove
}: {
  className?: string;
  countdown: CountlyCountdown;
  currentTime: Date;
  activeMenuId: string | null;
  onMenuToggle: (id: string) => void;
  onEdit: (countdown: CountlyCountdown) => void;
  onRemove: (id: string) => void;
}) {
  return (
    <article className={`countly-countdown-card ${className}`.trim()}>
      <div
        className={`countly-countdown-image ${countdown.image ? "" : "countly-countdown-image--empty"}`}
        style={countdown.image ? { backgroundImage: `url(${countdown.image})` } : undefined}
      >
        {countdown.image ? null : <CalendarDays size={28} />}

        <CountdownTimeOverlay
          currentTime={currentTime}
          targetDate={countdown.targetDate}
          ariaLabel={`Tempo restante para ${countdown.name}`}
        />
      </div>

      <div className="countly-countdown-details">
        <div className="countly-countdown-details__content">
          <h3>{countdown.name}</h3>
          <div className="countly-countdown-meta">
            <Calendar size={18} />
            <time dateTime={countdown.targetDate}>{formatDateLabel(countdown.targetDate)}</time>
          </div>
          {countdown.description ? <p>{countdown.description}</p> : null}
        </div>

        <div className="countly-card-menu countly-card-menu--details">
          <button
            className="countly-card-menu-trigger"
            type="button"
            onClick={() => onMenuToggle(countdown.id)}
            aria-expanded={activeMenuId === countdown.id}
            aria-label={`Abrir acoes para ${countdown.name}`}
          >
            <MoreVertical size={18} />
          </button>

          {activeMenuId === countdown.id ? (
            <div className="countly-card-menu-popover" role="menu">
              <button type="button" role="menuitem" onClick={() => onEdit(countdown)}>
                <Pencil size={16} />
                Editar
              </button>
              <button type="button" role="menuitem" onClick={() => onRemove(countdown.id)}>
                <Trash2 size={16} />
                Excluir
              </button>
            </div>
          ) : null}
        </div>
      </div>
    </article>
  );
}
