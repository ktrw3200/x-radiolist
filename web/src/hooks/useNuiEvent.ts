import { useEffect, useRef } from "react";

interface NuiMessageData<T = unknown> {
  data: T;
}

type NuiHandlerSignature<T> = (data: T) => void;

export const useNuiEvent = <T = unknown>(handler: (data: T) => void) => {
  const savedHandler = useRef<NuiHandlerSignature<T>>(() => {});

  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const eventListener = (event: NuiMessageData<T>) => {
      console.log(event.data);
      const data = event.data;

      if (savedHandler.current) {
        savedHandler.current(data);
      }
    };

    window.addEventListener("message", eventListener);

    return () => window.removeEventListener("message", eventListener);
  }, []);
};
