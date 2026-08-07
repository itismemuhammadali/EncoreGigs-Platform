class EmojiConstants {
  // Extended emoji collection with 32+ emojis
  static const List<String> allEmojis = [
    // Smileys & Emotion
    '😀', '😂', '😍', '😘', '😎', '🤔', '😢', '😡',
    '😠', '😤', '😞', '😖', '😣', '😫', '🤨', '😒',
    '😤', '😠', '😠', '🤬', '😈', '👿', '💀', '☠️',
    
    // Hearts & Love
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '🤎', '💔', '💕', '💞', '💓', '💗', '💖', '💘',
    
    // Gestures & Celebration
    '👍', '👎', '👏', '🙌', '👏', '🙏', '💪', '🤝',
    '🎉', '🎊', '🎈', '🎁', '🏆', '⭐', '✨', '🔥',
    
    // Music & Entertainment
    '🎵', '🎶', '🎤', '🎧', '🎸', '🎹', '🎺', '🥁',
    '🎭', '🎬', '🎪', '🎨', '🎯', '🎲', '🃏', '🎰',
    
    // Common
    '💯', '✅', '❌', '⚠️', '⏰', '⏱️', '⌛', '📱',
    '💻', '🔔', '📢', '📣', '📞', '📧', '💬', '📝',
  ];

  // Get emoji by index (for picker grid)
  static String getEmojiByIndex(int index) {
    if (index >= 0 && index < allEmojis.length) {
      return allEmojis[index];
    }
    return '😀';
  }

  // Total emoji count
  static int get emojiCount => allEmojis.length;
}
