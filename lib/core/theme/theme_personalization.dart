enum StudentMoodTheme {
  focusBlue,
  energyOrange,
  calmMint,
  sunsetCoral,
  midnightPurple,
}

enum ThemeTextureStyle { flat, paperGrain, softMesh }

enum ThemeScheduleMode { timeOfDay }

const moodThemeLabels = <StudentMoodTheme, String>{
  StudentMoodTheme.focusBlue: 'Focus Blue',
  StudentMoodTheme.energyOrange: 'Energy Orange',
  StudentMoodTheme.calmMint: 'Calm Mint',
  StudentMoodTheme.sunsetCoral: 'Sunset Coral',
  StudentMoodTheme.midnightPurple: 'Midnight Purple',
};

const textureStyleLabels = <ThemeTextureStyle, String>{
  ThemeTextureStyle.flat: 'Clean Flat',
  ThemeTextureStyle.paperGrain: 'Paper Grain',
  ThemeTextureStyle.softMesh: 'Soft Mesh',
};
