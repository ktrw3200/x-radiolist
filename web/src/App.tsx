import { useState } from "react";
import { useNuiEvent } from "./hooks/useNuiEvent";
import { Message } from "./types/message";

function App() {
  const [visible, setVisible] = useState<boolean>(true);
  const [channel, setChannel] = useState<string | null>(null);
  const [players, setPlayers] = useState<Record<number, { name: string; self: boolean; talking: boolean }>>({});

  useNuiEvent((data: Message) => {
    if ("radioId" in data) {
      if ("channel" in data) {
        setChannel((prevChannel) => prevChannel ?? data.channel);
      }

      setPlayers((prevPlayers) => {
        const updatedPlayers = { ...prevPlayers };

        if ("radioName" in data) {
          updatedPlayers[data.radioId] = {
            name: data.radioName,
            self: data.self,
            talking: false,
          };
        } else if ("radioTalking" in data) {
          if (updatedPlayers[data.radioId]) {
            updatedPlayers[data.radioId].talking = !!data.radioTalking;
          }
        } else {
          delete updatedPlayers[data.radioId];
        }

        return updatedPlayers;
      });
    }

    if ("clearRadioList" in data) {
      setChannel(null);
      setPlayers({});
    }

    if ("visible" in data) {
      setVisible(!!data.visible);
    }
  });

  return (
    visible && (
      <div className="radio-list-container" id="radio-list">
        {channel && <div id="radio-list-header">\uD83D\uDCE1Radio {channel}</div>}
        {Object.entries(players).map(([id, item]) => (
          <div key={id} id={`radio-list-item-${id}`} className={`${item.talking ? "talking" : null} ${item.self ? "self" : null}`}>
            {item.name}
            {item.self ? "\uD83D\uDD38" : "\uD83D\uDD39"}
          </div>
        ))}
      </div>
    )
  );
}

export default App;
