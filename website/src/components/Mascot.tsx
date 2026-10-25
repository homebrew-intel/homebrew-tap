import { useEffect, useRef, useState, type ReactNode } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import useBottles, { type Bottle } from "@site/src/hooks/useBottles";
import styles from "./Mascot.module.css";

const GREETING = "Click me for a fresh pour!";
const BUBBLES_PER_CHEER = 7;
const MAX_LEAN_DEGREES = 6;

function cheerLine(cheers: number, bottles: Bottle[]): string {
  const lines = [
    "Cheers! 🍻",
    "No compiling tonight. 🍺",
    "Fresh from the Sequoia keg.",
    "Intel Macs: not dead yet!",
  ];
  const bottle = bottles[Math.floor(Math.random() * bottles.length)];
  if (bottle && cheers % 2 === 1) {
    return `Just poured ${bottle.name} ${bottle.version}. Still warm!`;
  }
  return lines[cheers % lines.length];
}

// Leans the robot toward the pointer. Skipped for reduced motion.
function useLean(target: React.RefObject<HTMLElement | null>): number {
  const [lean, setLean] = useState(0);
  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    let frame = 0;
    const onMove = (event: PointerEvent) => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        const box = target.current?.getBoundingClientRect();
        if (!box) return;
        const offset = (event.clientX - (box.left + box.width / 2)) / window.innerWidth;
        setLean(Math.max(-1, Math.min(1, offset * 2)) * MAX_LEAN_DEGREES);
      });
    };
    window.addEventListener("pointermove", onMove);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("pointermove", onMove);
    };
  }, [target]);
  return lean;
}

export default function Mascot(): ReactNode {
  const robot = useRef<HTMLButtonElement>(null);
  const lean = useLean(robot);
  const bottles = useBottles();
  const [cheers, setCheers] = useState(0);
  const [line, setLine] = useState(GREETING);

  function cheer(): void {
    const ready = bottles.status === "ready" ? bottles.bottles : [];
    setLine(cheerLine(cheers, ready));
    setCheers(cheers + 1);
  }

  return (
    <div className={styles.stage}>
      <p className={styles.speech} aria-live="polite">{line}</p>
      <button
        ref={robot}
        type="button"
        className={styles.robot}
        style={{ transform: `rotate(${lean}deg)` }}
        onClick={cheer}
        aria-label="Raise a toast with the homebrew-intel bot"
      >
        {/* Re-keying on each cheer restarts the wobble and bubble animations. */}
        <span key={cheers} className={cheers > 0 ? styles.wobble : undefined}>
          <img src={useBaseUrl("/homebrew-intel-bot.svg")} alt="" width={260} height={260} />
          {cheers > 0 &&
            Array.from({ length: BUBBLES_PER_CHEER }, (_, index) => (
              <span
                key={index}
                className={styles.bubble}
                style={{ "--i": index, "--size": `${8 + (index % 3) * 5}px` } as React.CSSProperties}
              />
            ))}
        </span>
      </button>
      <p className={styles.counter}>
        {cheers === 0 ? "The bot is thirsty." : `${cheers} ${cheers === 1 ? "round" : "rounds"} poured`}
      </p>
    </div>
  );
}
