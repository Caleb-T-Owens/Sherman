import { Outlet } from '@tanstack/react-router';
import { Box } from '@radix-ui/themes';

export function RootLayout() {
  return (
    <Box p="4" style={{ minHeight: '100vh' }}>
      <Outlet />
    </Box>
  );
}
