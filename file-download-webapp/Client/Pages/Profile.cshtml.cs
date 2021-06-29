using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Security.Claims;

namespace Client.Pages
{
    [Authorize]
    public class ProfileModel : PageModel
    {
        public ClaimsPrincipal CurrentPrincipal { get; set; }

        public ProfileModel()
        {
        }

        public void OnGet()
        {
            this.CurrentPrincipal = this.HttpContext.User;
        }
    }
}
