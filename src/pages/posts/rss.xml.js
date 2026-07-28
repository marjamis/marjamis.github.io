import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import { SITE_TITLE, SITE_DESCRIPTION } from '../../consts';

export async function GET(context) {
	const posts = (await getCollection("posts"))
  .sort((a, b) => b.data.publishedDate.valueOf() - a.data.publishedDate.valueOf())
  .slice(0, 25);

	return rss({
		title: SITE_TITLE,
		description: SITE_DESCRIPTION,
		site: context.site,

		items: posts.map((post) => ({
			...post.data,
			link: `/posts/${post.id}/`,
			pubDate: post.data.publishedDate,
		})),
	});
}
