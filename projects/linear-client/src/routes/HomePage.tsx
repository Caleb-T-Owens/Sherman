import { Heading, Text, Flex } from '@radix-ui/themes';

export function HomePage() {
  return (
    <Flex direction="column" gap="3">
      <Heading size="8">Linear Client</Heading>
      <Text size="3" color="gray">
        A keyboard-first interface for Linear.
      </Text>
    </Flex>
  );
}
