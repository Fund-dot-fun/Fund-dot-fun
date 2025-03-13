import { motion } from "motion/react";
import { Plus } from "lucide-react";
import { useState } from "react";
import { Button } from "@shadcn/button";
import { NavLink } from "react-router";

const MENUS = [
  {
    text: "Home",
    to: "/",
  },
  {
    text: "Market",
    to: "/market",
  },
  {
    text: "Create",
    to: "/",
  },
];

export default function FloatingActionButton() {
  const [active, setActive] = useState(false);

  return (
    <div className="fixed container bottom-10 flex items-center justify-center w-full">
      <div className="relative flex items-center justify-center gap-4 px-2 backdrop-blur-lg rounded-full bg-background/30">
        <motion.div
          className="absolute left-0 z-10 w-full rounded-[40px] bg-background"
          animate={{
            x: active ? "calc(100% + 20px)" : 0,
            backgroundColor: active ? "rgba(0,0,0,0)" : "var(--background)",
          }}
          transition={{ type: "ease-in", duration: 0.5 }}
        >
          <motion.button
            className="flex size-12 items-center justify-center rounded-full bg-slate-800 sm:size-20 cursor-pointer"
            onClick={() => setActive(!active)}
            animate={{ rotate: active ? 45 : 0 }}
            transition={{
              type: "ease-in",
              duration: 0.5,
            }}
          >
            <Plus size={40} strokeWidth={3} className="text-white" />
          </motion.button>
        </motion.div>
        {MENUS.map((val, index) => (
          <motion.div
            className="size-10 sm:size-16 flex flex-col gap-2 items-center justify-center cursor-pointer"
            animate={{
              filter: active ? "blur(0px)" : "blur(2px)",
              scale: active ? 1 : 0.9,
              rotate: active ? 0 : 45,
            }}
            transition={{
              type: "ease-in",
              duration: 0.4,
            }}
            key={index}
          >
            <NavLink to={val.to}>
              <Button variant="link">{val.text}</Button>
            </NavLink>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
