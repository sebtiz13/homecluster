/**
 * sets the quota an additional claim in the token with quota metadata as value an project as key
 *
 * The quota claims of the token look like the following:
 *
 * // added by the code below
 * "quota": "...",
 *
 * Flow: Complement token, Triggers: Pre Userinfo creation, Pre access token creation
 *
 * @param ctx
 * @param api
 */
function quotaClaim(ctx, api) {
  const metadata = ctx.v1.user.getMetadata();
  if (metadata === undefined || metadata.count == 0) {
    return;
  }

  let result = "";
  metadata.metadata.forEach((item) => {
    if (item.key == "quota") {
      result = item.value;
    }
  });

  if (result != "") {
    api.v1.claims.setClaim("quota", result);
  }
}
