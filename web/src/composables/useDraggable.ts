import { computed, onBeforeUnmount, onMounted, ref, type Ref } from "vue";

type Point = { x: number; y: number };

// Keeps the dragged element this far away from the screen edges
const EDGE = 8;

function load(key: string): Point | null {
  try {
    const value = JSON.parse(localStorage.getItem(key) ?? "null");
    return Number.isFinite(value?.x) && Number.isFinite(value?.y) ? { x: value.x, y: value.y } : null;
  } catch {
    return null;
  }
}

function save(key: string, point: Point | null) {
  try {
    if (point) localStorage.setItem(key, JSON.stringify(point));
    else localStorage.removeItem(key);
  } catch {
    // Storage can be unavailable; the position then only lasts for this session
  }
}

/**
 * Free positioning for a fixed element. The position survives the element being
 * hidden, and is stored so it survives reloads too. `null` means "use the default layout".
 */
export function useDraggable(target: Ref<HTMLElement | null>, storageKey: string) {
  const position = ref<Point | null>(load(storageKey));
  const dragging = ref(false);
  let offset: Point = { x: 0, y: 0 };

  function clamp(point: Point): Point {
    const width = target.value?.offsetWidth ?? 0;
    const height = target.value?.offsetHeight ?? 0;

    return {
      x: Math.min(Math.max(point.x, EDGE), Math.max(EDGE, window.innerWidth - width - EDGE)),
      y: Math.min(Math.max(point.y, EDGE), Math.max(EDGE, window.innerHeight - height - EDGE)),
    };
  }

  function onPointerMove(event: PointerEvent) {
    position.value = clamp({ x: event.clientX - offset.x, y: event.clientY - offset.y });
  }

  function stopDrag() {
    if (!dragging.value) return;

    dragging.value = false;
    window.removeEventListener("pointermove", onPointerMove);
    window.removeEventListener("pointerup", stopDrag);
    window.removeEventListener("pointercancel", stopDrag);
    save(storageKey, position.value);
  }

  function startDrag(event: PointerEvent) {
    if (event.button !== 0 || !target.value) return;

    const rect = target.value.getBoundingClientRect();
    offset = { x: event.clientX - rect.left, y: event.clientY - rect.top };
    position.value = { x: rect.left, y: rect.top };
    dragging.value = true;

    window.addEventListener("pointermove", onPointerMove);
    window.addEventListener("pointerup", stopDrag);
    window.addEventListener("pointercancel", stopDrag);
    event.preventDefault();
  }

  function reset() {
    position.value = null;
    save(storageKey, null);
  }

  /** Pulls a stored position back on screen, e.g. after a resolution change. */
  function refit() {
    if (position.value) position.value = clamp(position.value);
  }

  const style = computed(() =>
    position.value ? { left: `${position.value.x}px`, top: `${position.value.y}px` } : undefined,
  );

  onMounted(() => window.addEventListener("resize", refit));
  onBeforeUnmount(() => {
    stopDrag();
    window.removeEventListener("resize", refit);
  });

  return { position, dragging, style, startDrag, reset, refit };
}
