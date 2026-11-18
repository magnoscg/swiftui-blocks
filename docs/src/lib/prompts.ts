// Prompts that work, grouped by what people want, each with the component it finds. Only the ids
// live here: the title and the category come from catalog.json, so a renamed component fails the build.
import { components } from './catalog';

const groups = [
  {
    title: 'Make it feel alive',
    prompts: [
      ['Add a like button that bursts into hearts', 'like-burst-button'],
      ['Make the delete button fire only after a long press', 'hold-to-confirm-button'],
      ['Throw confetti when the order goes through', 'confetti-burst'],
    ],
  },
  {
    title: 'Onboard and sell',
    prompts: [
      ['Add a three-page onboarding with a Continue button', 'onboarding-pager'],
      ['Build a paywall that shows what happens each day of the trial', 'trial-timeline-paywall'],
      ['Show what this version brings, once per version', 'whats-new-sheet'],
    ],
  },
  {
    title: 'Show the numbers',
    prompts: [
      ['Show my three daily goals as activity rings', 'activity-rings'],
      ['Add a line chart I can scrub with a finger', 'interactive-line-chart'],
      ['A calendar heatmap of my daily streak', 'contribution-heatmap'],
    ],
  },
  {
    title: 'Use the newest iOS',
    prompts: [
      ['Group my editing tools in a Liquid Glass strip', 'glass-tool-strip'],
      ['Let the tab bar shrink while I scroll', 'minimizing-tab-bar'],
      ['Fill a form from a free-form note with the on-device model', 'structured-output-form'],
    ],
  },
];

export const promptGroups = groups.map((group) => ({
  ...group,
  prompts: group.prompts.map(([prompt, id]) => {
    const component = components.find((candidate) => candidate.id === id);
    if (!component) throw new Error(`The prompts name "${id}", which is not in catalog.json.`);
    return { prompt, component };
  }),
}));
