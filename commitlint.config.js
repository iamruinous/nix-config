module.exports = {
  extends: ['@commitlint/config-conventional'],
  parserPreset: {
    parserOpts: {
      // Allow optional emoji prefix before the type (e.g., "✨ feat(scope): subject")
      headerPattern: /^(?:.*\s)?(\w*)(?:\((.*)\))?!?: (.*)$/,
      headerCorrespondence: ['type', 'scope', 'subject'],
    },
  },
  plugins: [
    {
      rules: {
        'ai-footer': ({raw}) => {
          const footer = '🤖 Generated with [ruinous.ai](https://agent.ruinous.ai) 🦾✨';
          return [
            raw.includes(footer),
            `AI agents must include the footer: ${footer}`,
          ];
        },
      },
    },
  ],
  rules: {
    'ai-footer': [1, 'always'],
  },
};
