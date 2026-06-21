"use client";

import {
  Calendar,
  CalendarDays,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  CircleCheck,
  X,
  Globe2,
  ImageUp,
  MoreVertical,
  Moon,
  Pencil,
  Plus,
  Repeat2,
  Sun,
  Trash2,
  Undo2
} from "lucide-react";
import { ChangeEvent, DragEvent, FormEvent, useEffect, useMemo, useRef, useState } from "react";

type CountlyRepeatMode = "none" | "daily" | "weekly" | "monthly";

type CountlyCountdown = {
  id: string;
  name: string;
  targetDate: string;
  repeat: CountlyRepeatMode;
  description?: string;
  image?: string;
};

type CountlyFormState = {
  name: string;
  targetDate: string;
  repeat: CountlyRepeatMode;
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
const maxStoredImagePixels = 900;
const maxStoredImageBytes = 220_000;

const initialFormState: CountlyFormState = {
  name: "",
  targetDate: "",
  repeat: "none",
  image: ""
};

const repeatLabels: Record<CountlyRepeatMode, string> = {
  none: "Nao",
  daily: "Dia.",
  weekly: "Sem.",
  monthly: "Men."
};

function getDataUrlByteSize(dataUrl: string) {
  return Math.ceil((dataUrl.length * 3) / 4);
}

function fileToDataUrl(file: File) {
  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

function compactImageForStorage(source: string) {
  if (!source.startsWith("data:image/") || getDataUrlByteSize(source) <= maxStoredImageBytes) {
    return Promise.resolve(source);
  }

  return new Promise<string>((resolve) => {
    const image = new Image();

    image.onload = () => {
      const canvas = document.createElement("canvas");
      const scale = Math.min(1, maxStoredImagePixels / Math.max(image.naturalWidth, image.naturalHeight));
      const width = Math.max(1, Math.round(image.naturalWidth * scale));
      const height = Math.max(1, Math.round(image.naturalHeight * scale));

      canvas.width = width;
      canvas.height = height;

      const context = canvas.getContext("2d");
      if (!context) {
        resolve(source);
        return;
      }

      context.drawImage(image, 0, 0, width, height);

      const compacted = canvas.toDataURL("image/webp", 0.72);
      resolve(compacted.length < source.length ? compacted : source);
    };

    image.onerror = () => resolve(source);
    image.src = source;
  });
}

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

function formatCalendarMonthName(date: Date) {
  return new Intl.DateTimeFormat("pt-BR", {
    month: "long"
  }).format(date);
}

function toDateInputValue(date: Date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function getMonthCalendarDays(year: number, month: number) {
  const firstDay = new Date(year, month, 1);
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const emptyCells = firstDay.getDay();

  return [
    ...Array.from({ length: emptyCells }, () => null),
    ...Array.from({ length: daysInMonth }, (_, index) => new Date(year, month, index + 1))
  ];
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
      targetDate: normalizeTargetDate(countdown.targetDate),
      repeat: countdown.repeat ?? "none"
    }));
  } catch {
    return [];
  }
}

export default function CountlyApp() {
  const datePickerRef = useRef<HTMLDivElement>(null);
  const previewImageInputRef = useRef<HTMLInputElement>(null);
  const [countdowns, setCountdowns] = useState<CountlyCountdown[]>([]);
  const [countdownForm, setCountdownForm] = useState<CountlyFormState>(initialFormState);
  const [sortMode, setSortMode] = useState<"soonest" | "latest">("soonest");
  const [activeView, setActiveView] = useState<"countdowns" | "calendar">("countdowns");
  const [currentTime, setCurrentTime] = useState(new Date());
  const [storageLoaded, setStorageLoaded] = useState(false);
  const [creationPopoverOpen, setCreationPopoverOpen] = useState(false);
  const [creationPanelClosing, setCreationPanelClosing] = useState(false);
  const [datePickerOpen, setDatePickerOpen] = useState(false);
  const [editingCountdownId, setEditingCountdownId] = useState<string | null>(null);
  const [activeMenuId, setActiveMenuId] = useState<string | null>(null);
  const [theme, setTheme] = useState<"light" | "dark">("light");
  const [visibleMonth, setVisibleMonth] = useState(() => new Date(new Date().getFullYear(), new Date().getMonth(), 1));
  const [dateInputDraft, setDateInputDraft] = useState("");

  useEffect(() => {
    let active = true;

    async function loadStoredCountdowns() {
      const storedCountdowns = getStoredCountdowns();
      const compactedCountdowns = await Promise.all(
        storedCountdowns.map(async (countdown) => ({
          ...countdown,
          image: countdown.image ? await compactImageForStorage(countdown.image) : countdown.image
        }))
      );

      if (active) {
        setCountdowns(compactedCountdowns);
        setStorageLoaded(true);
      }
    }

    void loadStoredCountdowns();

    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    if (storageLoaded) {
      try {
        window.localStorage.setItem(storageKey, JSON.stringify(countdowns));
      } catch (error) {
        console.warn("Nao foi possivel salvar as contagens no armazenamento local.", error);
      }
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

  const calendarYear = currentTime.getFullYear();

  const annualCalendarMonths = useMemo(() => {
    return Array.from({ length: 12 }, (_, monthIndex) => ({
      key: `${calendarYear}-${monthIndex}`,
      monthDate: new Date(calendarYear, monthIndex, 1),
      days: getMonthCalendarDays(calendarYear, monthIndex)
    }));
  }, [calendarYear]);

  const countdownsByDate = useMemo(() => {
    return visibleCountdowns.reduce<Map<string, CountlyCountdown[]>>((calendarMap, countdown) => {
      const normalizedDate = normalizeTargetDate(countdown.targetDate);
      if (!normalizedDate) {
        return calendarMap;
      }

      const countdownsForDate = calendarMap.get(normalizedDate) ?? [];
      countdownsForDate.push(countdown);
      calendarMap.set(normalizedDate, countdownsForDate);
      return calendarMap;
    }, new Map());
  }, [visibleCountdowns]);

  function updateFormField<Key extends keyof CountlyFormState>(key: Key, value: CountlyFormState[Key]) {
    setCountdownForm((current) => ({ ...current, [key]: value }));
  }

  async function handleCreateCountdown(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!countdownForm.name.trim() || !countdownForm.targetDate) {
      return;
    }

    const compactImage = countdownForm.image ? await compactImageForStorage(countdownForm.image) : "";

    const savedCountdown: CountlyCountdown = {
      id: editingCountdownId ?? crypto.randomUUID(),
      name: countdownForm.name.trim(),
      targetDate: normalizeTargetDate(countdownForm.targetDate),
      repeat: countdownForm.repeat,
      image: compactImage
    };

    setCountdowns((current) => {
      if (editingCountdownId) {
        return current.map((countdown) => (countdown.id === editingCountdownId ? savedCountdown : countdown));
      }

      return [savedCountdown, ...current];
    });
    setCountdownForm(initialFormState);
    setEditingCountdownId(null);
    setCreationPopoverOpen(false);
    setCreationPanelClosing(false);
    setDatePickerOpen(false);
  }

  function removeCountdown(id: string) {
    setCountdowns((current) => current.filter((countdown) => countdown.id !== id));
    if (editingCountdownId === id) {
      setEditingCountdownId(null);
      setCountdownForm(initialFormState);
      setCreationPopoverOpen(false);
      setCreationPanelClosing(false);
    }
    setActiveMenuId(null);
  }

  function editCountdown(countdown: CountlyCountdown) {
    setCountdownForm({
      name: countdown.name,
      targetDate: countdown.targetDate,
      repeat: countdown.repeat ?? "none",
      image: countdown.image ?? ""
    });
    setEditingCountdownId(countdown.id);
    setCreationPanelClosing(false);
    setCreationPopoverOpen(true);
    setActiveMenuId(null);
    document.getElementById("new-countdown")?.scrollIntoView({ behavior: "smooth", block: "nearest" });
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

  function openCreatePopover() {
    setCountdownForm(initialFormState);
    setEditingCountdownId(null);
    setActiveMenuId(null);
    setCreationPanelClosing(false);
    setCreationPopoverOpen(true);
  }

  function closeCreatePanel() {
    setDatePickerOpen(false);
    setCreationPanelClosing(true);
    window.setTimeout(() => {
      setCountdownForm(initialFormState);
      setEditingCountdownId(null);
      setCreationPopoverOpen(false);
      setCreationPanelClosing(false);
    }, 190);
  }

  async function readPreviewImageFile(file: File | undefined) {
    if (!file || !file.type.startsWith("image/")) {
      return;
    }

    const imageDataUrl = await fileToDataUrl(file);
    const compactImage = await compactImageForStorage(imageDataUrl);
    updateFormField("image", compactImage);
  }

  function handlePreviewImageUpload(event: ChangeEvent<HTMLInputElement>) {
    void readPreviewImageFile(event.target.files?.[0]);
    event.target.value = "";
  }

  function handlePreviewImageDrop(event: DragEvent<HTMLDivElement>) {
    event.preventDefault();
    void readPreviewImageFile(event.dataTransfer.files?.[0]);
  }

  return (
    <main className="countly-application-shell" data-theme={theme}>
      <header className="countly-navigation-bar">
        <div className="countly-brand-lockup">
          <img className="countly-brand-logo" src="/Logo-name.svg" alt="Countly" />
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
        {activeView === "countdowns" ? (
          <div className="countly-creation-heading" id="new-countdown">
            <h1>Suas contagens <span>{visibleCountdowns.length}</span></h1>
            <p>Crie e acompanhe seus momentos importantes.</p>
          </div>
        ) : null}

        {activeView === "countdowns" ? (
          <>
            <div className={`countly-add-card-shell ${creationPopoverOpen ? "countly-add-card-shell--open" : ""}`}>
              <button
                className={`countly-add-card ${creationPopoverOpen ? "countly-add-card--preview" : ""}`}
                type="button"
                onClick={openCreatePopover}
                aria-expanded={creationPopoverOpen}
              >
                {creationPopoverOpen ? (
                  <>
                    <div
                      className={`countly-add-card__preview-image ${
                        countdownForm.image ? "countly-add-card__preview-image--selected" : ""
                      }`}
                      style={countdownForm.image ? { backgroundImage: `url(${countdownForm.image})` } : undefined}
                    >
                      <span className="countly-add-card__image-empty" aria-hidden="true">
                        <ImageUp size={28} />
                      </span>
                      {!countdownForm.image ? (
                        <span className="countly-add-card__preview-message">
                          Adicione uma imagem para visualizar o card
                        </span>
                      ) : null}
                      <CountdownTimeOverlay
                        className="countly-time-grid--creation-preview"
                        currentTime={currentTime}
                        targetDate={countdownForm.targetDate}
                        ariaLabel="Tempo restante da pre-visualizacao"
                      />
                    </div>
                    <div className="countly-add-card__preview-details">
                      <strong>{countdownForm.name.trim() || "Nome da contagem"}</strong>
                      <em>
                        <Calendar size={15} />
                        {countdownForm.targetDate ? formatDateLabel(countdownForm.targetDate) : "Data da contagem"}
                      </em>
                    </div>
                  </>
                ) : (
                  <span className="countly-add-card__icon" aria-hidden="true">
                    <Plus size={34} />
                  </span>
                )}
              </button>
            </div>

            {creationPopoverOpen || creationPanelClosing ? (
              <>
                <button
                  className={`countly-drawer-backdrop ${creationPanelClosing ? "countly-drawer-backdrop--closing" : ""}`}
                  type="button"
                  aria-label="Fechar menu lateral"
                  onClick={closeCreatePanel}
                />
                <section
                  className={`countly-creation-panel-inline ${
                    creationPanelClosing ? "countly-creation-panel-inline--closing" : "countly-creation-panel-inline--open"
                  }`}
                  aria-label="Adicionar nova contagem"
                >
                <button
                  className="countly-creation-panel-close"
                  type="button"
                  aria-label="Fechar"
                  onClick={closeCreatePanel}
                >
                  <X size={18} />
                </button>

                <div
                  className={`countly-add-card__preview-image countly-drawer-image-uploader ${
                    countdownForm.image ? "countly-add-card__preview-image--selected" : ""
                  }`}
                  style={countdownForm.image ? { backgroundImage: `url(${countdownForm.image})` } : undefined}
                  onDragOver={(event) => event.preventDefault()}
                  onDrop={handlePreviewImageDrop}
                >
                  <span className="countly-add-card__image-empty" aria-hidden="true">
                    <ImageUp size={30} />
                  </span>
                  <span
                    className={`countly-add-card__image-button ${countdownForm.image ? "countly-add-card__image-button--change" : ""}`}
                    role="button"
                    tabIndex={0}
                    onClick={() => previewImageInputRef.current?.click()}
                    onKeyDown={(event) => {
                      if (event.key === "Enter" || event.key === " ") {
                        event.preventDefault();
                        previewImageInputRef.current?.click();
                      }
                    }}
                  >
                    {countdownForm.image ? (
                      <ImageUp size={22} />
                    ) : (
                      <>
                        Adicione uma imagem para a contagem
                        <small>Arraste um arquivo aqui ou selecione do computador</small>
                      </>
                    )}
                  </span>
                  <input
                    ref={previewImageInputRef}
                    accept="image/jpeg,image/png,image/webp"
                    onChange={handlePreviewImageUpload}
                    type="file"
                  />
                </div>

                <form className="countly-creation-form-inline" onSubmit={handleCreateCountdown}>
                  <label className="countly-field-group countly-field-group--name">
                    <span>Nome</span>
                    <input
                      value={countdownForm.name}
                      onChange={(event) => updateFormField("name", event.target.value)}
                      placeholder="ex.: Meu aniversario"
                      required
                    />
                  </label>

                  <label className="countly-field-group countly-field-group--date">
                    <span>Data</span>
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
                          aria-label="Data"
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

                  <div className="countly-field-group countly-repeat-toggle-field">
                    <span>Repetir</span>
                    <div className="countly-repeat-toggle" role="radiogroup" aria-label="Repetir">
                      {(["none", "daily", "weekly", "monthly"] as CountlyRepeatMode[]).map((repeatMode) => (
                        <button
                          className={countdownForm.repeat === repeatMode ? "countly-repeat-toggle__option--active" : ""}
                          key={repeatMode}
                          type="button"
                          role="radio"
                          aria-checked={countdownForm.repeat === repeatMode}
                          onClick={() => updateFormField("repeat", repeatMode)}
                        >
                          {repeatMode === "none" ? <X size={16} /> : repeatLabels[repeatMode]}
                        </button>
                      ))}
                    </div>
                  </div>

                  <button className="countly-submit-button" type="submit">
                    <CalendarDays size={19} />
                    {editingCountdownId ? "Salvar" : "Adicionar"}
                  </button>
                </form>
                </section>
              </>
            ) : null}

            {visibleCountdowns.map((countdown) => (
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
          </>
        ) : (
          <section className="countly-list-section" aria-labelledby="countly-list-title">
            <div className="countly-list-toolbar">
              <h2 id="countly-list-title">
                Calendario {calendarYear} <span>{visibleCountdowns.length}</span>
              </h2>
            </div>

            <div className="countly-year-calendar" aria-label={`Calendario anual de ${calendarYear}`}>
              {annualCalendarMonths.map((month) => (
                <section className="countly-year-month" key={month.key} aria-label={formatCalendarMonthName(month.monthDate)}>
                  <h3>{formatCalendarMonthName(month.monthDate)}</h3>
                  <div className="countly-year-month__weekdays" aria-hidden="true">
                    {["D", "S", "T", "Q", "Q", "S", "S"].map((weekday, index) => (
                      <span key={`${weekday}-${index}`}>{weekday}</span>
                    ))}
                  </div>
                  <div className="countly-year-month__days">
                    {month.days.map((date, index) => {
                      if (!date) {
                        return <span className="countly-year-day countly-year-day--empty" key={`empty-${month.key}-${index}`} />;
                      }

                      const isoDate = toDateInputValue(date);
                      const countdownsForDate = countdownsByDate.get(isoDate) ?? [];
                      const hasCountdowns = countdownsForDate.length > 0;

                      return (
                        <div
                          className={`countly-year-day ${hasCountdowns ? "countly-year-day--has-countdowns" : ""}`}
                          key={isoDate}
                        >
                          <button type="button" aria-label={hasCountdowns ? `${countdownsForDate.length} contagem em ${formatDateLabel(isoDate)}` : formatDateLabel(isoDate)}>
                            <span>{date.getDate()}</span>
                            {hasCountdowns ? <i aria-hidden="true" /> : null}
                          </button>

                          {hasCountdowns ? (
                            <div className="countly-year-day-popover" role="tooltip">
                              {countdownsForDate.map((countdown) => (
                                <CountdownHoverCard
                                  key={countdown.id}
                                  countdown={countdown}
                                  currentTime={currentTime}
                                />
                              ))}
                            </div>
                          ) : null}
                        </div>
                      );
                    })}
                  </div>
                </section>
              ))}
            </div>

            {visibleCountdowns.length === 0 ? (
              <div className="countly-empty-state countly-empty-state--calendar">
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

function CountdownHoverCard({
  countdown,
  currentTime
}: {
  countdown: CountlyCountdown;
  currentTime: Date;
}) {
  return (
    <article className="countly-calendar-hover-card">
      <CountdownTimeOverlay
        currentTime={currentTime}
        targetDate={countdown.targetDate}
        ariaLabel={`Tempo restante para ${countdown.name}`}
      />
      <div>
        <h4>{countdown.name}</h4>
        <p>
          <Calendar size={14} />
          <time dateTime={countdown.targetDate}>{formatDateLabel(countdown.targetDate)}</time>
        </p>
        {countdown.repeat && countdown.repeat !== "none" ? <span>{repeatLabels[countdown.repeat]}</span> : null}
      </div>
    </article>
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
      {remainingTime.months > 0 ? <CountdownMetric label="Meses" value={remainingTime.months} /> : null}
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
      />

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

      <CountdownTimeOverlay
        currentTime={currentTime}
        targetDate={countdown.targetDate}
        ariaLabel={`Tempo restante para ${countdown.name}`}
      />

      <div className="countly-countdown-details">
        <h3>{countdown.name}</h3>
        <div className="countly-countdown-meta">
          <Calendar size={18} />
          <time dateTime={countdown.targetDate}>{formatDateLabel(countdown.targetDate)}</time>
          {countdown.repeat && countdown.repeat !== "none" ? (
            <span className="countly-repeat-label">
              <Repeat2 size={13} />
              {repeatLabels[countdown.repeat]}
            </span>
          ) : null}
        </div>
      </div>
    </article>
  );
}
