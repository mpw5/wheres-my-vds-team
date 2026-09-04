import type { ReactNode } from 'react';

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="en">
      <head>
        <link rel="stylesheet" href="/styles.css" />
      </head>
      <body>
        <div className="content">{children}</div>
        <footer />
      </body>
    </html>
  );
}
