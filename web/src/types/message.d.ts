type ClearListMsg = {
  clearRadioList: true;
};

type ToggleVisibleMsg = {
  changeVisibility: true;
  visible: boolean;
};

type AddPlayerMsg = {
  self: boolean;
  radioId: number;
  radioName: string;
  channel: string;
};

type RemovePlayerMsg = {
  radioId: number;
};

type UpdateStatusMsg = {
  radioId: number;
  radioTailking: boolean;
};

export type Message = ClearListMsg | AddPlayerMsg | RemovePlayerMsg | UpdateStatusMsg;
