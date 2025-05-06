export const SITE = {
  website: "https://fastcode.guru/",
  author: "Carlos Reyes",
  profile: "",
  desc: "A place to discuss software performance and quality from the perspective of computer programmers.",
  title: "Fast Code Guru",
  ogImage: "/images/fastcodeguru-logo-1200x630.png",
  lightAndDarkMode: true,
  postPerIndex: 4,
  postPerPage: 4,
  scheduledPostMargin: 15 * 60 * 1000, // 15 minutes
  showArchives: true,
  showBackButton: true, // show back button in post detail
  editPost: {
    enabled: true,
    text: "Suggest Changes",
    url: "https://github.com/carlos-reyes-123/fastcodeguru/edit/main/",
  },
  dynamicOgImage: true,
  lang: "en", // html lang code. Set this empty and default will be "en"
  timezone: "America/Los_Angeles", // Default global timezone (IANA format) https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
} as const;
