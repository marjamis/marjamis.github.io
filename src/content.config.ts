import { defineCollection } from 'astro:content';
import { z } from 'astro/zod';
import { glob } from 'astro/loaders';

const defaultLoaderPattern = "**/*.{md,mdx}"

const posts = defineCollection({
	loader: glob({
		base: "./src/content/posts",
		pattern: defaultLoaderPattern,
	}),
	// Type-check frontmatter using a schema
	schema: z.object({
		title: z.string(),
		description: z.string(),
		// Transform string to Date object
		publishedDate: z.coerce.date(),
		updatedDate: z.coerce.date().optional(),
		heroImage: z.string(),
		tags: z.string().array(),
	}),
});

const fit_together = defineCollection({
	loader: glob({
		base: "./src/content/fit_together",
		pattern: defaultLoaderPattern,
	}),
	// Type-check frontmatter using a schema
	schema: z.object({
		title: z.string(),
		resources: z.object({
			title: z.string(),
			description: z.string().optional(),
			link: z.string().optional(),
		}).array().optional(),
	}),
});

const documentation = defineCollection({
	loader: glob({
		base: "./src/content/documentation",
		pattern: defaultLoaderPattern,
	}),
	// Type-check frontmatter using a schema
	schema: z.object({
		title: z.string(),
		heroImage: z.string().optional(),
		resources: z.object({
			title: z.string(),
			description: z.string().optional(),
			link: z.string().optional(),
		}).array().optional(),
	}),
});

export const collections = {
	posts: posts,
	fit_together: fit_together,
	documentation: documentation,
};
