import type { ReactNode } from 'react';
import {
  ActivityIndicator,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
  type TextInputProps,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

export const colors = {
  background: '#0F1115',
  surface: '#1A1D24',
  border: '#2A2F3A',
  text: '#F4F5F7',
  muted: '#9AA3B2',
  accent: '#FF6B3D',
  danger: '#FF5470',
  success: '#3DDC97',
};

export function Screen({ children, testID, scroll = true }: { children: ReactNode; testID?: string; scroll?: boolean }) {
  return (
    <SafeAreaView style={styles.safe} edges={['bottom', 'left', 'right']} testID={testID}>
      {scroll ? (
        <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
          {children}
        </ScrollView>
      ) : (
        <View style={styles.content}>{children}</View>
      )}
    </SafeAreaView>
  );
}

export function Title({ children }: { children: ReactNode }) {
  return <Text style={styles.title}>{children}</Text>;
}

export function Body({ children, muted }: { children: ReactNode; muted?: boolean }) {
  return <Text style={[styles.body, muted && styles.muted]}>{children}</Text>;
}

export function Button({
  title,
  onPress,
  testID,
  variant = 'primary',
  loading,
  disabled,
}: {
  title: string;
  onPress: () => void;
  testID?: string;
  variant?: 'primary' | 'secondary' | 'danger';
  loading?: boolean;
  disabled?: boolean;
}) {
  const inactive = disabled || loading;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: !!inactive, busy: !!loading }}
      testID={testID}
      onPress={onPress}
      disabled={inactive}
      style={({ pressed }) => [
        styles.button,
        variant === 'secondary' && styles.buttonSecondary,
        variant === 'danger' && styles.buttonDanger,
        (pressed || inactive) && styles.buttonDimmed,
      ]}
    >
      {loading ? <ActivityIndicator color={colors.text} /> : <Text style={styles.buttonText}>{title}</Text>}
    </Pressable>
  );
}

export function Field({ label, ...props }: TextInputProps & { label: string }) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput placeholderTextColor={colors.muted} style={styles.input} {...props} />
    </View>
  );
}

export function ToggleRow({
  label,
  value,
  onValueChange,
  testID,
}: {
  label: string;
  value: boolean;
  onValueChange: (value: boolean) => void;
  testID?: string;
}) {
  return (
    <View style={styles.toggleRow}>
      <Text style={[styles.body, styles.toggleLabel]}>{label}</Text>
      <Switch testID={testID} value={value} onValueChange={onValueChange} trackColor={{ true: colors.accent }} />
    </View>
  );
}

export function Choice({
  label,
  detail,
  selected,
  onPress,
  testID,
}: {
  label: string;
  detail?: string;
  selected: boolean;
  onPress: () => void;
  testID?: string;
}) {
  return (
    <Pressable
      accessibilityRole="radio"
      accessibilityState={{ selected }}
      testID={testID}
      onPress={onPress}
      style={[styles.choice, selected && styles.choiceSelected]}
    >
      <Text style={styles.choiceLabel}>{label}</Text>
      {detail ? <Text style={styles.muted}>{detail}</Text> : null}
    </Pressable>
  );
}

export function ErrorBanner({ message, testID }: { message: string | null; testID?: string }) {
  if (!message) return null;
  return (
    <View style={styles.error} accessibilityRole="alert">
      <Text testID={testID} style={styles.errorText}>
        {message}
      </Text>
    </View>
  );
}

export function Card({ children, onPress, testID }: { children: ReactNode; onPress?: () => void; testID?: string }) {
  return (
    <Pressable testID={testID} onPress={onPress} disabled={!onPress} style={styles.card}>
      {children}
    </Pressable>
  );
}

export const formatPrice = (cents: number, currency: string) =>
  `${currency === 'USD' ? '$' : `${currency} `}${(cents / 100).toFixed(2)}`;

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  content: { padding: 20, gap: 14 },
  title: { color: colors.text, fontSize: 26, fontWeight: '700' },
  body: { color: colors.text, fontSize: 16, lineHeight: 22 },
  muted: { color: colors.muted, fontSize: 14 },
  button: {
    backgroundColor: colors.accent,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
  },
  buttonSecondary: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border },
  buttonDanger: { backgroundColor: colors.danger },
  buttonDimmed: { opacity: 0.6 },
  buttonText: { color: colors.text, fontSize: 16, fontWeight: '600' },
  field: { gap: 6 },
  label: { color: colors.muted, fontSize: 13, textTransform: 'uppercase', letterSpacing: 0.5 },
  input: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 10,
    color: colors.text,
    fontSize: 16,
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  toggleRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  toggleLabel: { flex: 1 },
  choice: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 12,
    padding: 14,
    gap: 4,
  },
  choiceSelected: { borderColor: colors.accent },
  choiceLabel: { color: colors.text, fontSize: 16, fontWeight: '600' },
  error: { backgroundColor: '#3A1620', borderRadius: 10, padding: 12 },
  errorText: { color: colors.danger, fontSize: 14 },
  card: { backgroundColor: colors.surface, borderRadius: 14, padding: 16, gap: 6 },
});
