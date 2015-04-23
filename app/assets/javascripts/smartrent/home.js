      $(function(){
          $("#slides").slides({
     			generateNextPrev: true,
			next: 'next',
			prev: 'prev',
			animationComplete: function(current) {
				// Get the total number of pages
				var totalPages=0;
				if (totalPages == 0){
					$('.threeWide').each(function(i){
						totalPages=i+1;
					});
				}
				console.log('page '+current+' out of '+totalPages+' total pages.');
				//if not on the first page, then display the "prev" button
				if (current != 1){
					$('.prev').css('display','block');
				}else{
					$('.prev').css('display','none');
				}
				//if not on the last page, then display the "next" button
				if (current != totalPages){
					$('.next').css('display','block');
				}else{
					$('.next').css('display','none');
				}
			}
		});
      });
		$(document).ready(function(){
			//homepage slideshow functions
			var initHeight;
			$('.propertySlide').hover(function(){
				initHeight=$(this).find('.caption').css('bottom');
				$(this).find('.caption').animate({bottom:0});
			},function(){
				$(this).find('.caption').animate({bottom:initHeight});
			});
		});
